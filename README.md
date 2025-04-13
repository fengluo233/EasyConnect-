
# HUST VPN(EasyConnect) 连接后无法访问外网问题解决

这个脚本包含了 **华中科技大学 (HUST)** 的 EasyConnect 配置和管理，用于 Windows 和 macOS 系统。脚本能够自动执行以下任务：
- 删除当前系统路由表中过于繁杂的 VPN 相关路由规则。
- 添加新的路由规则到系统路由表，确保网络访问正常，**可以在使用校园VPN的同时使用代理软件**。

## 1. Windows 系统使用方法

### 1.1 前置条件
- 确保 **EasyConnect** 客户端已正确安装在 Windows 上，并且路径为 `C:/Program Files (x86)/Sangfor/SSL/EasyConnect`。
- 确保 **EasyConnect** 客户端已打开

### 1.2 执行脚本
1. 下载脚本并赋予执行权限。
2. 运行脚本以启动 EasyConnect 配置路由：
   ```bash
   .\easyconnect_fix_hust_win.sh
   ```

### 1.3 脚本功能
- **检查网络**：脚本会解析 `vpn.hust.edu.cn` 的域名，并获取其 IP 地址。
- **启动 EasyConnect**：通过 Windows 命令行启动 EasyConnect 应用程序。
- **路由操作**：删除当前与 VPN 相关的路由规则，并添加新的路由规则确保网络访问正常。

### 1.4 其他信息
- **VPN 域名**：`vpn.hust.edu.cn`。
- **系统要求**：Windows 操作系统，并已安装 EasyConnect 客户端。
- **权限要求**：脚本需要管理员权限来修改系统的路由表。

### 1.5 问题排查
- 确保 EasyConnect 已正确安装并可以通过命令行启动。
- 脚本需要管理员权限才能删除和添加路由规则，确保你有足够的权限。
- 如果 EasyConnect 没有成功启动，请检查应用是否已正确安装并且可以手动启动。

## 2. macOS 系统使用方法

### 2.1 前置条件
- 确保 **EasyConnect** 客户端已正确安装在 macOS 上，路径为 `/Applications/EasyConnect.app`。
- **EasyConnect** 客户端未打开。

### 2.2 执行脚本
1. 下载脚本并赋予执行权限：
   ```bash
   chmod +x easyconnect_hust_macos.sh
   ```
2. 运行脚本以启动 EasyConnect 并配置路由：
   ```bash
   ./easyconnect_hust_macos.sh
   ```

### 2.3 脚本功能
- **检查网络**：脚本会解析 `vpn.hust.edu.cn` 的域名，并获取其 IP 地址。
- **启动 EasyConnect**：通过 macOS 的 `open -a EasyConnect` 启动 EasyConnect 应用。
- **路由操作**：删除当前与 VPN 相关的路由规则，并添加新的路由规则确保网络访问正常。

### 2.4 其他信息
- **VPN 域名**：`vpn.hust.edu.cn`。
- **系统要求**：macOS 系统，并且已经安装了 EasyConnect 客户端。
- **权限要求**：脚本需要 `sudo` 权限来修改系统的路由表。

### 2.5 问题排查
- 确保 EasyConnect 客户端已正确安装在 `/Applications/EasyConnect.app` 路径下。
- 脚本需要管理员权限才能删除和添加路由规则，确保你有足够的权限。
- 如果 EasyConnect 没有成功启动，请检查应用是否已正确安装并且可以手动启动。
