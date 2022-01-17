import { NativeModules } from 'react-native';

const { SmartCropper } = NativeModules;

export enum Orientation {
  /** 默认方向 */
  Up = 1,
  /** 水平翻转 */
  UpMirrored = 2,
  /**  旋转 180° */
  Down = 3,
  /** 垂直翻转 */
  DownMirrored = 4,
  /** 水平翻转并逆时针旋转 90° */
  Left = 5,
  /** 顺时针旋转 90° */
  LeftMirrored = 6,
  /** 水平翻转并顺时针旋转 90° */
  Right = 7,
  /** 顺时针旋转 90° */
  RightMirrored = 8,
}

export enum CropType {
  /**
   * 基于注意力
   */
  Attention = 1,
  /**
   * 基于对象
   */
  Object = 2,
  /**
   * 基于人脸
   */
  Face = 3,
}

export const enum ImageFormat {
  JPEG = 1,
  PNG = 2,
}

export interface Options {
  /**
   * 图像重点区域类型，支持两种类型：基于注意力、基于对象
   * @default `CropType.AttentionBased`
   **/
  cropType?: CropType;
  /**
   * 指定保存图像结果的类型
   * @default `ImageFormat.JPEG`
   **/
  saveFormat?: ImageFormat;
  /**
   * 结果图像的压缩级别，仅 `saveFormat` 为 `jpeg` 时有效 [0.0 - 1.0]
   * @default 1
   **/
  quality?: number;
  /**
   * 如果设置为true，则此属性会减少请求的内存占用、处理占用和 CPU/GPU 争用，但可能会花费更长的执行时间。
   * @default false
   **/
  preferBackgroundProcessing?: boolean;
  /**
   * 仅在 CPU 上执行。
   * @default false
   **/
  usesCPUOnly?: boolean;
  /**
   * 图像的方向
   * @default Up
   **/
  orientation?: Orientation;
}

export interface Result {
  /**
   * 裁剪后图像的路径
   */
  path: string;
  /**
   * 置信度，[0.0 - 1.0]
   */
  confidence: number;
  /**
   * 人脸的捕捉质量，[0.0 - 1.0]。仅当 `corpType` 为 `CropType.Face` 时返回
   */
  faceCaptureQuality?: number;
  /**
   * 边界框
   */
  boundingBox: {
    /**
     * 边框位置，原点为图像右上角
     */
    x: number;
    y: number;
    width: number;
    height: number;
  };
}

export function request(path: string, options: Options): Promise<Result[]> {
  if (
    typeof options.quality === 'number' &&
    (options.quality < 0 || options.quality > 1)
  ) {
    throw Error('Quality must be greater than 0 and less than 1.');
  }

  return SmartCropper.request({
    path,
    ...options,
  });
}
