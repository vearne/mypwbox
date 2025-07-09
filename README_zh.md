# mypwbox

mypwbox是一个密码管理工具，支持基于对象存储进行数据备份和同步。
* [README](https://github.com/vearne/mypwbox/blob/master/README.md)

**警告**: 关键密码不宜存储于电子文档中，最安全的方式是牢记于心。


## 使用
### 获取安装包
1) 直接下载
[release](https://github.com/vearne/mypwbox/releases)
2) 手动打包
```
make dmg
```
### 离线模式。
默认为离线模式
### 在线模式
支持S3协议的对象存储都可以使用
* AWS S3
* [Aliyun OSS](https://help.aliyun.com/zh/oss/user-guide/regions-and-endpoints)
* [Tencent COS](https://cloud.tencent.com/document/product/436/6224)
* MinIO

## 开发
### 安装 Flutter
为了开发mypwbox，你需要安装 [Flutter](https://flutter.dev/) 

官方安装指导 [Flutter installation guide](https://docs.flutter.dev/get-started/install) 

- [下载 Flutter](https://docs.flutter.dev/get-started/install)

安装完成之后，验证一下
```bash
flutter --version
```
### Clone代码库，并在本地运行
```bash
# Clone the repository
git clone https://github.com/vearne/mypwbox.git
cd mypwbox

# Install dependencies
flutter pub get

# Run on macOS
flutter run -d macos
```

![](./img/s3.jpg)
![](./img/login.jpg)
![](./img/list.jpg)