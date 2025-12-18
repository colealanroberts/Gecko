import FoundationEssentials
import WinAppSDK
import WinSDK

public final class GeckoApp {

    // MARK: - Private Properties

    private let viewModel: ViewModel
    private var logger: Logging

    // MARK: - Init

    init() {
        let configurationProvider = ConfigurationProvider()
        let config = configurationProvider.load()
        let logger = Logger(logLevel: config.logLevel)

        let notificationPresenter = NotificationPresenter(
            logger: logger
        )
        
        if !notificationPresenter.isSupported {
            let message = "Gecko requires Windows notification support. Please ensure you're running Windows 10 or later."
            logger.critical(message)
            precondition(notificationPresenter.isSupported, message)
        }
        
        let httpClient = CoreHTTPClient(
            logger: logger
        )

        let gpuLookupService = GPULookupService(
            httpClient: httpClient,
            logger: logger
        )

        let systemInfoProvider = SystemInfoProvider(
            logger: logger
        )

        let router: ApplicationRouting = ApplicationRouter(
            logger: logger
        )

        let updateService = UpdateService(
            httpClient: httpClient,
            gpuLookupService: gpuLookupService,
            systemInfoProvider: systemInfoProvider,
            logger: logger
        )

        self.viewModel = GeckoApp.ViewModel(
            httpClient: httpClient,
            updateService: updateService,
            notificationPresenter: notificationPresenter,
            router: router,
            logger: logger
        )

        self.logger = logger

        logger.debug("[-] Finished launching.")
    }

    // MARK:  - Public Methods
    
    func launch() {
        viewModel.prepare()
    }
}

// MARK: - GeckoApp+ViewModel

extension GeckoApp {
    final class ViewModel {

        // MARK: - Private Properties

        private let httpClient: HTTPClient
        private let updateService: any UpdateServicing
        private let notificationPresenter: any NotificationPresenting
        private let router: ApplicationRouting
        private let logger: Logging

        // MARK: - Init

        init(
            httpClient: HTTPClient,
            updateService: any UpdateServicing,
            notificationPresenter: any NotificationPresenting,
            router: ApplicationRouting,
            logger: Logging
        ) {
            self.httpClient = httpClient
            self.updateService = updateService
            self.notificationPresenter = notificationPresenter
            self.router = router
            self.logger = logger
        }

        // MARK: - Public Methods

        func prepare() {
            Task {
                do {
                    if let download = try await updateService.fetch() {
                        presentUpdateNotification(for: download)
                    }
                } catch {
                    logger.warning(error.localizedDescription)
                }
            }
        }

        // MARK: - Private Methods

        private func presentUpdateNotification(
            for download: DriverResponse.Download
        ) {
            let notification = UI.ActionNotification(
                title: "New Nvidia driver available",
                subtitle: "Version \(download.version)",
                actions: [
                    .default("Download") { [weak self] in
                        guard let self else { return }
                        onDownloadClicked(download: download)
                        logger.debug("Download clicked.")
                    },
                    .cancel,
                    .contextMenuItem("View release notes") { [weak router, weak logger] in
                        guard let url = download.detailsURL else { return }
                        router?.open(url: url)
                        logger?.debug("View release notes clicked.")
                    }
                ]
            )

            notificationPresenter.present(notification)
        }

        private func onDownloadClicked(
            download: DriverResponse.Download
        ) {
            var taskIdentifier: String?

            let onCancel: (String?) -> Void = { [weak self] taskId in
                guard let taskId else { return }
                self?.httpClient.cancel(id: taskId)
            }

            let notification = UI.ProgressNotification(
                title: "Downloading driver",
                subtitle: "Version \(download.version)",
                actions: [
                    .default("Cancel") { [weak logger] in
                        onCancel(taskIdentifier)
                        logger?.debug("Cancel download clicked.")
                    },
                    .contextMenuItem("Cancel download") {
                        onCancel(taskIdentifier)
                    }
                ]
            )

            notificationPresenter.present(notification)

            startDownload(
                download, 
                notification: notification,
                onTaskIdentifier: { taskId in
                    if taskIdentifier != taskId {
                        taskIdentifier = taskId
                    }
                }
            )
        }

        private func startDownload(
            _ download: DriverResponse.Download,
            notification: UI.ProgressNotification,
            onTaskIdentifier: @escaping (String?) -> Void
        ) {
            logger.debug("Starting download: \(download.url.absoluteString)")
            
            Task {
                do {
                    let downloadURL = try await self.httpClient.download(
                        url: download.url, 
                        onChange: { [weak self] snapshot in
                            onTaskIdentifier(snapshot.identifier)

                            if let update = notification.update(snapshot: snapshot) {
                                guard let self else { return }

                                notificationPresenter.update(
                                    data: update,
                                    in: notification
                                )
                                
                                 logger.debug("Downloading \(snapshot.identifier ?? "")...\(snapshot.percentage ?? 0)%")
                            }
                        }
                    )

                    logger.debug("File downloaded to: \(downloadURL.absoluteString)")

                    // When our download is complete - we'll dismiss our progress notification
                    // and spawn a new notification.
                    await MainActor.run {
                        notificationPresenter.dismiss(id: notification.id)

                        presentCompletionNotification(
                            fileName: download.fileName, 
                            url: downloadURL
                        )
                    }    
                } catch {
                    logger.warning(error.localizedDescription)
                }
            }
        }

        private func presentCompletionNotification(
            fileName: String,
            url: URL
        ) {
            let notification = UI.ActionNotification(
                title: "Download completed",
                actions: [
                    .cancel,
                    .default("Launch installer") { [weak router, weak logger] in
                        router?.open(url: url)
                        logger?.debug("Launch installer clicked.")
                    }
                ]
            )

            notificationPresenter.present(notification)
        }
    }
}