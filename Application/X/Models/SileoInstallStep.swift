import Foundation

/// 用于表示Sileo安装过程中的各个步骤
public enum SileoInstallStep {
    case downloadingSileo
    case extractingPackage
    case extractingBootstrap
    case configuringPermissions
    case registeringURLScheme
    case setupAptSources
    case installDependencies
    
    var description: String {
        switch self {
        case .downloadingSileo:
            return "正在下载Sileo"
        case .extractingPackage:
            return "正在解压Sileo包"
        case .extractingBootstrap:
            return "正在解压bootstrap"
        case .configuringPermissions:
            return "正在配置权限"
        case .registeringURLScheme:
            return "正在注册URL Scheme"
        case .setupAptSources:
            return "正在设置APT源"
        case .installDependencies:
            return "正在安装依赖"
        }
    }
}
