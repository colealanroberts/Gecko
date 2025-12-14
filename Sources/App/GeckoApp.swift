import Foundation
import CWinRT
import WinAppSDK
import WindowsFoundation
import WinUI

@_spi(WinRTImplements) import WindowsFoundation

public final class GeckoApp: Application {

    // MARK: - Private Properties

    private var window: Window?
    private let viewModel: ViewModel

    // MARK: - Init

    override init() {
        let httpClient = CoreHTTPClient()

        let gpuLookupService = GPULookupService(
            httpClient: httpClient
        )

        let updateService = UpdateService(
            httpClient: httpClient,
            gpuLookupService: gpuLookupService
        )

        let notificationPresenter = NotificationPresenter()

        self.viewModel = GeckoApp.ViewModel(
            httpClient: httpClient,
            updateService: updateService,
            notificationPresenter: notificationPresenter
        )
        
        super.init()
    }

    // MARK: - Public Methods

    override public func onLaunched(_ args: WinUI.LaunchActivatedEventArgs?) throws {
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

        // MARK: - Init

        init(
            httpClient: HTTPClient,
            updateService: any UpdateServicing,
            notificationPresenter: any NotificationPresenting
        ) {
            self.httpClient = httpClient
            self.updateService = updateService
            self.notificationPresenter = notificationPresenter
        }

        // MARK: - Public Methods

        func prepare() {
            Task {
                do {
                    if let download = try await updateService.fetch() {
                        presentUpdateNotification(for: download)
                    }
                } catch {

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

                    print(fileURL)
                } catch {

                }
            }
        }
    }
}