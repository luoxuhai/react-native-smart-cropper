# react-native-smart-cropper

智能裁剪图像重点区域的 react-native 库，支持基于注意力、对象和人脸。 | A react-native library for intelligently cropping key areas of images, supporting attention based, object and face based.

<img style="width: 100%;margin: 0 auto;" src="https://s4.ax1x.com/2022/01/16/7tyeYQ.png" />
<p style="color: #999;text-align: center" >原图、基于注意力、基于对象</p>

识别结果示例，`confidence`（置信度，[0 - 1]区间内的小数）的值越大可信度越高。基于注意力模式下最多返回 1 个区域，基于对象模式下最多返回 3 个区域。

```js
[
  {
    confidence: 0.848;
    path: "file:///private/mobile/Application/tmp/25D8F7E7-9A52-4E1C-A0D2-3CE07CF7E452.jpg",
    boundingBox: {
        "height": 1841.765625,
        "width": 2071.6171875,
        "x": 825.3984375,
        "y": 1128.09375
      }
  }
]
```

## ❗️ :warning:

目前基于人脸的裁剪支持 iOS 11.0+，基于注意力、对象的裁剪仅支持 iOS 13.0+，

## Installation

`$ npm install react-native-smart-cropper --save`

or

`$ yarn add react-native-smart-cropper`

```sh
# RN >= 0.60
cd ios && pod install
# RN < 0.60
react-native link react-native-smart-cropper
```

## Usage

### 简单使用

```js
import * as SmartCropper from 'react-native-smart-cropper';

SmartCropper.request(path) // 本地路径
  .then((result) => {
    // success
  })
  .catch((error) => {
    // error
  });
```

### 高级使用 (使用网络图像)

```js
import * as SmartCropper from 'react-native-smart-cropper';
import RNFS from 'react-native-fs';

const path = `${RNFS.TemporaryDirectoryPath}/IMG_1234.jpg`;

// https://github.com/itinance/react-native-fs
RNFS.downloadFile({
  fromUrl: 'https://s4.ax1x.com/2022/01/15/7JJaDI.png',
  toFile: path,
}).promise.then((res) => {
  SmartCropper.request(path, {
    cropType: SmartCropper.CropType.Object,
    saveFormat: SmartCropper.ImageFormat.JPEG,
    quality: 0.8,
  })
    .then((result) => {
      // success
    })
    .catch((error) => {
      // error
    });
});
```

## API

### `request(path: string, options?: Object): Promise<{Result[]>`

| 参数               | 类型   | 描述                                                                                                                   |
| ------------------ | ------ | ---------------------------------------------------------------------------------------------------------------------- |
| **path**           | string | 图像文件的本地绝对路径. 可使用 [react-native-fs constants](https://github.com/itinance/react-native-fs#constants) 获取 |
| **options** (可选) | object | 可选项，见下 `Options`                                                                                                 |

### Options

| 参数                                  | 类型    | 描述                                                                                                   | 默认值               |
| ------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------ | -------------------- |
| **cropType** (可选)                   | number  | 图像裁剪类型，支持两种类型：基于注意力、基于对象 、基于人脸                                            | `CropType.Attention` |
| **saveFormat** (可选)                 | number  | 指定保存图像结果的类型                                                                                 | `ImageFormat.JPEG`   |
| **quality** (可选)                    | number  | 结果图像的压缩级别，仅 `saveFormat` 为 `jpeg` 时有效 [0.0 - 1.0]                                       | 1                    |
| **preferBackgroundProcessing** (可选) | boolean | 如果设置为 `true`，则此属性会减少请求的内存占用、处理占用和 CPU/GPU 争用，但可能会花费更长的执行时间。 | false                |
| **usesCPUOnly** (可选)                | boolean | 仅在 CPU 上执行。设置 `false` 表示可以自由地利用 GPU 来加速其处理。                                    | false                |
| **orientation** (可选)                | number  | 图像的方向                                                                                             | `Orientation.Up`     |

### Result - 识别结果

| 名称                   | 类型   | 描述                                                                      |
| ---------------------- | ------ | ------------------------------------------------------------------------- |
| **confidence**         | number | 置信度，[0 - 1]                                                           |
| **path**               | string | 裁剪后图像的路径                                                          |
| **faceCaptureQuality** | number | 人脸的捕捉质量，[0.0 - 1.0]。仅当 `corpType` 为 `CropType.Face` 时返回    |
| **boundingBox**        | object | 重点区域边界框 `{ x: number; y: number; width: number; height: number; }` |

### CropType

- `CropType.Attention`: `1` - 基于注意力
- `CropType.Object`: `2` - 基于对象
- `CropType.Face`: 3` - 基于人脸

### ImageFormat

- `ImageFormat.JPEG`: `1` - jpg 格式
- `ImageFormat.PNG`: `2` - png 格式

### Orientation

- `Orientation.Up`: `1` - 默认方向
- `Orientation.UpMirrored`: `2` - 水平翻转
- `Orientation.Down`: `3` - 旋转 180°
- `Orientation.DownMirrored`: `4` - 垂直翻转
- `Orientation.Left`: `5` - 水平翻转并逆时针旋转 90°
- `Orientation.LeftMirrored`: `6` - 顺时针旋转 90°
- `Orientation.Right`: `7` - 水平翻转并顺时针旋转 90°
- `Orientation.RightMirrored`: `8` - 顺时针旋转 90°

## Troubleshooting

1. 检查您的最低 iOS 版本。react-native-smart-cropper 要求最低 iOS 版本为 11.0。
   - 打开你的 Podfile
   - 确保 `platform :ios` 设置为 11.0 或更高
   - 确保 `iOS Deployment Target` 设置为 11.0 或更高
2. 确保您在项目中创建了 Swift 桥接头。
   - 使用 Xcode 打开你的项目（**xxx.xcworkspace**）
   - 按照以下步骤创建 Swift 文件 **File > New > File (⌘+N)**
   - 选择 **Swift File** 并点击 **Next**
   - 输入文件名 **BridgingFile.swift**，然后点击创建，提示时点击 **Create Bridging Header**

## TODO

- [ ] 支持网络图像

## License

MIT
