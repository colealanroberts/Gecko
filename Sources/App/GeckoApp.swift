import FoundationEssentials
import WinAppSDK
import WindowsFoundation

@_spi(WinRTImplements) import WindowsFoundation

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

        let updateService = UpdateService(
            httpClient: httpClient,
            gpuLookupService: gpuLookupService,
            logger: logger
        )

        self.viewModel = GeckoApp.ViewModel(
            httpClient: httpClient,
            updateService: updateService,
            notificationPresenter: notificationPresenter,
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
        private let logger: Logging

        // MARK: - Init

        init(
            httpClient: HTTPClient,
            updateService: any UpdateServicing,
            notificationPresenter: any NotificationPresenting,
            logger: Logging
        ) {
            self.httpClient = httpClient
            self.updateService = updateService
            self.notificationPresenter = notificationPresenter
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
                    .cancel,
                    .default("Download") { [weak self] in
                        self?.onDownloadClicked(download: download)
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

            let progress = UI.ProgressNotification(
                title: "Downloading driver",
                subtitle: "Version \(download.version)",
                actions: [
                    .default("Cancel") {
                        onCancel(taskIdentifier)
                    }
                ]
            )

            notificationPresenter.present(progress)

            startDownload(
                url: download.url, 
                notification: progress,
                onTaskIdentifier: { taskId in
                    if taskIdentifier != taskId {
                        taskIdentifier = taskId
                    }
                }
            )
        }

        private func startDownload(
            url: URL,
            notification: UI.ProgressNotification,
            onTaskIdentifier: @escaping (String?) -> Void
        ) {
            Task {
                do {
                    let fileURL = try await self.httpClient.download(
                        url: url, 
                        onChange: { snapshot in
                            onTaskIdentifier(snapshot.identifier)

                            if let update = notification.update(snapshot: snapshot) {
                                self.notificationPresenter.update(
                                    data: update,
                                    in: notification
                                )
                            }
                        }
                    )
                } catch {
                    logger.warning(error.localizedDescription)
                }
            }
        }
    }
}