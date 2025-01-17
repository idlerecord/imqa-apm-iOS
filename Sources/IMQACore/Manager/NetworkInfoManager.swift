//
//  File.swift
//  Imqa-sdk-ios
//
//  Created by Hunta on 2024/10/22.
//

import Foundation

import SystemConfiguration.CaptiveNetwork
import Network

class NetworkInfoManager: NSObject {
    private  override init(){
        super.init()
        if #available(iOS 12, *) {
            self.monitor = NWPathMonitor()
        }else{
            self.reachability = try! Reachability()
        }
        self.localIpAddress = getIPAddress()
        fetchPublicIPAddress {[weak self] ip in
            self?.publicIP = ip ?? ""
            self?.networkReachableBlock?()
        }
        checkNetworkSetting()
    }
    
    var reachability:Reachability?
    var monitor: NWPathMonitor?
    
    var networkReachableBlock:(() -> Void)?
    
    var isReachable: Bool = false{
        didSet{
            if isReachable {
                fetchPublicIPAddress {[weak self] ip in
                    self?.publicIP = ip ?? ""
                    self?.networkReachableBlock?()
                }
            }
        }
    }
    var isWifi: Bool = false
    var isCellular: Bool = false
    
    var publicIP: String = ""
    var localIpAddress: String = ""
    
    static let sharedInstance: NetworkInfoManager = NetworkInfoManager()
    
    /// 인터넷 상태 책크
    func checkNetworkSetting() {
        if #available(iOS 12, *) {
            monitor?.pathUpdateHandler = {[weak self] path in
                if path.status == .satisfied {
                    if path.usesInterfaceType(.wifi) {
                        self?.isWifi = true
                        self?.isCellular = false
                    } else if path.usesInterfaceType(.cellular) {
                        self?.isWifi = false
                        self?.isCellular = true
                    }
                    self?.isReachable = true
                } else {
                    self?.isReachable = false
                }
                self?.networkReachableBlock?()
            }
            let queue = DispatchQueue(label: "NetworkMonitor")
            monitor?.start(queue: queue)
        }else{
            reachability?.whenReachable = {[weak self] reachability in
                if reachability.connection == .wifi {
                    self?.isWifi = true
                    self?.isCellular = false
                } else {
                    self?.isWifi = false
                    self?.isCellular = true
                }
                self?.isReachable = true
                self?.networkReachableBlock?()
            }
            
            reachability?.whenUnreachable = { [weak self] _ in
                self?.isReachable = false
                self?.networkReachableBlock?()
            }
            
            do {
                try reachability?.startNotifier()
            } catch {
                print("Unable to start notifier")
            }
        }
    }

    
    func stopMoniterNetworkStatus(){
        if #available(iOS 12, *) {
            monitor?.cancel()
        }else{
            reachability?.stopNotifier()
        }
    }
    
    func getIPAddress() -> String {
        var address: String?
        var port: String = "en0"
        if self.isWifi {
            port = "en0"
        }else if self.isCellular{
            port = "pdp_ip0"
        }
        // Create a network interface query
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var pointer = ifaddr
            while pointer != nil {
                let interface = pointer!.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family
                
                // Check for IPv4 or IPv6 address
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    if let ifaName = String(cString: interface.ifa_name, encoding: .utf8), ifaName == port {
                        // Convert the network address to a string
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
                pointer = pointer!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        return address ?? ""
    }
        
    func fetchPublicIPAddress(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.ipify.org?format=json") else{
            completion(nil)
            return
        }

        let task = URLSession.shared.dataTask(with: url) {[weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching public IP: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            // 解析 JSON 响应
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let ip = json["ip"] as? String {
                    completion(ip) // 返回公共 IP
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }

        task.resume()
    }
    
}
