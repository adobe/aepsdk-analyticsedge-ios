# Adobe Experience Platform Analytics Edge Mobile Extension

> **Warning**
This extension no longer maintained. Refer to [Edge Bridge](https://github.com/adobe/aepsdk-edgebridge-ios) extension for iOS. 

## BETA

AEPAnalyticsEdge is currently in beta. Use of this code is by invitation only and not otherwise supported by Adobe. Please contact your Adobe Customer Success Manager to learn more.

By using the Beta, you hereby acknowledge that the Beta is provided "as is" without warranty of any kind. Adobe shall have no obligation to maintain, correct, update, change, modify or otherwise support the Beta. You are advised to use caution and not to rely in any way on the correct functioning or performance of such Beta and/or accompanying materials.

## About this project

The AEP Analytics Edge Mobile extension allows you to send analytics data to the Adobe Experience Platform (AEP) from a mobile application.

The Adobe Experience Platform Edge Mobile Extension is an extension for the [Adobe Experience Platform SDK](https://github.com/Adobe-Marketing-Cloud/acp-sdks).

## Current version
The Adobe Experience Platform Analytics Edge Mobile extension for iOS is currently in Beta development.

## Installation

### Binaries

To generate an `AEPAnalyticsEdge.xcframework`, run the following command:

```
make archive
```

This will generate the xcframework under the `build` folder. Drag and drop all the .xcframeworks to your app target.

### [CocoaPods](https://guides.cocoapods.org/using/using-cocoapods.html)

```ruby
# Podfile
use_frameworks!

target 'YOUR_TARGET_NAME' do
    pod 'AEPAnalyticsEdge', :git => 'git@github.com:adobe/aepsdk-analyticsedge-ios.git', :branch => 'main'	
end
```

## Development

The first time you clone or download the project, you should run the following from the root directory to setup the environment:

~~~
make pod-install
~~~

Subsequently, you can make sure your environment is updated by running the following:

~~~
make pod-update
~~~

#### Open the Xcode workspace
Open the workspace in Xcode by running the following command from the root directory of the repository:

~~~
make open
~~~

#### Command line integration

You can run all the test suites from command line:

~~~
make test
~~~

## Contributing

Contributions are welcomed! Read the [Contributing Guide](./.github/CONTRIBUTING.md) for more information.

## Licensing

This project is licensed under the Apache V2 License. See [LICENSE](LICENSE) for more information.
