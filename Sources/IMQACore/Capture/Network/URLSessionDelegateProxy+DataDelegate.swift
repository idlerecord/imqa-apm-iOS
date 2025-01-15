//
//  URLSessionDelegateProxy+DataDelegate.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/11/7.
//


import Foundation

extension URLSessionDelegateProxy: URLSessionDataDelegate {
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didBecome downloadTask: URLSessionDownloadTask) {
        let selector = #selector(
            URLSessionDataDelegate.urlSession(_:dataTask:didBecome:) as
            (URLSessionDataDelegate) -> ((URLSession, URLSessionDataTask, URLSessionDownloadTask) -> Void)?
        )

        invokeDelegates(session: session, selector: selector) { (delegate: URLSessionDataDelegate) in
            delegate.urlSession?(session, dataTask: dataTask, didBecome: downloadTask)
        }
    }

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didBecome streamTask: URLSessionStreamTask) {
        let selector = #selector(
            URLSessionDataDelegate.urlSession(_:dataTask:didBecome:) as
            (URLSessionDataDelegate) -> ((URLSession, URLSessionDataTask, URLSessionStreamTask) -> Void)?
        )

        invokeDelegates(session: session, selector: selector) { (delegate: URLSessionDataDelegate) in
            delegate.urlSession?(session, dataTask: dataTask, didBecome: streamTask)
        }
    }

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive data: Data) {
        let selector = #selector(
            URLSessionDataDelegate.urlSession(_:dataTask:didReceive:)
        )
        if var previousData = dataTask.imqaData {
            previousData.append(data)
            dataTask.imqaData = previousData
        } else {
            dataTask.imqaData = data
        }

        invokeDelegates(session: session, selector: selector) { (delegate: URLSessionDataDelegate) in
            delegate.urlSession?(session, dataTask: dataTask, didReceive: data)
        }
    }
}

// MARK: Methods with completion block
// We'd have to check the default values for each `completionHandler` first.
// In the meantime, the forwarding mechanism should be enough.
/*
extension URLSessionDelegateProxy {
    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    willCacheResponse proposedResponse:
                    CachedURLResponse,
                    completionHandler: @escaping @Sendable (CachedURLResponse?) -> Void) {

    }

    func urlSession(_ session: URLSession,
                    dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void) {
    }
}
*/
