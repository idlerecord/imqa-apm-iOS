# Welcome to Imqa-sdk-ios
IMQA는 모바일 세계에 대한 관찰 가능성입니다. 우리의 계측 및 통찰력을 통해 단순한 모니터링을 넘어 앱에 영향을 미치는 문제를 식별할 수 있습니다.

# IMQA Apple SDK를 수용하세요

IMQA Apple SDK는 iOS 앱을 계측하여 관찰 가능성 데이터를 수집합니다.
이 프로젝트는 보다 모듈화된 접근 방식을 채택하였습니다.
[OpenTelemetry](https://opentelemetry.io/) 표준을 지원합니다. 또한 OpenTelemetry를 확장하는 기능을 추가했습니다.
모바일 앱을 더 잘 지원합니다.

이 SDK를 통해 기록된 원격 측정은 Embrace 고객을 위한 IMQA 플랫폼에서 사용할 수 있지만, IMQA 고객이 아닌 사용자가 수집된 데이터를 자신이 호스팅하거나 다른 공급업체에서 호스팅하는 Otel Collector로 직접 내보내는 데 사용할 수도 있습니다. 실제로 이 SDK는 관찰 가능성을 위해 OpenTelemetry 생태계를 활용하고 싶지만 동시에 원하는 iOS 앱에 대해 [OpenTelemetry Swift SDK](https://github.com/open-telemetry/opentelemetry-swift)를 직접 사용하는 대신 사용할 수 있습니다. IMQA의 모든 고급 원격 측정 캡처 기능을 제공합니다.

## 특징

### 현재 지원되는 주요 기능

* Session capture
* Crash capture
* Network capture
* OTel trace capture
* Custom breadcrumbs
* Custom logs
* OpenTelemetry Export
* Session properties
* Automatic view tracking
* Network payload capture


## 시작하기

### 전제 조건
* IMQA를 사용하는 앱은 iOS 12.0 이상, macOS 10.13 이상을 대상으로 할 수 있습니다.
* Xcode 15.0 or 이상.

### 설치

* Via CocoaPods:

* Via Swift Package Manager:


### 소개
---

IMQA SDK 사용을 시작하기 위한 간략한 개요는 다음과 같습니다. 다음을 수행해야 합니다.
1. `IMQA` 모듈을 가져옵니다.
2. `IMQA.Options`를 `setup` 메소드에 전달하여 IMQA 클라이언트의 인스턴스를 생성합니다.
3. 해당 인스턴스에서 `start` 메소드를 호출합니다.

이 작업은 앱 런타임에서 가능한 한 빨리 수행되어야 합니다(예: `UIApplicationDelegate.applicationDidFinishLaunching(_:)`).
좋은 곳이 될 수 있어요.
---

다음은 코드 조각입니다.

```swift
import Imqa-sdk-ios
// ...

func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    do {
      try IMQA.setup(options: .init(appId: "myApp"))
      try IMQA.client?.start()
    } catch {
      // Unable to start Embrace
    }

    return true
}
```

**span 만들기:**
```swift
let span = IMQA.client?
  .buildSpan(name: "my-custom-operation", type: .performance)
  .startSpan()

// perform `my-custom-operation`

span?.end()
```

**User data 추가하기:**
```swift
IMQA.client?.metadata.userEmail = "testing.email@my-org.com"
IMQA.client?.metadata.userIdentifier = "827B02FE-D868-461D-8B4A-FE7371818369"
IMQA.client?.metadata.userName = "tony.the.tester"
````
