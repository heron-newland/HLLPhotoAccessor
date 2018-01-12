# HLLPhotoAccessor
使用Photo框架的方法, 以及封装

### Photos框架

使用方法: 将Source文件中的 HLLPhotoAccessor.h和HLLPhotoAccessor.m拖入工程总

#### 类作用介绍
*    PHPhotoLibrary

* 对相册内容进行修改(添加图片, 删除图片, 新建相册等)
* 监听相册内容的变化

*    PHObject

*  基类, 只有一个属性localIdentifier(只读的资源的唯一标示符)
*    相册里的所有资源对象(相片, 相册, 等)都继承自他

*    PHAsset

*    照片库中一个单独的资源(狭隘可以理解为一张图或者一段视频), 以元数据的方式提供, 包含所有该资源的信息(例如, 创建日期, 大小, 类型, 地点, 是否被标记为喜欢等等)
*     用来获取照片库中的PHAsset对象

*    PHLivePhoto(实时照片, 每张照片包含了前后几秒的短视频, 重压可以播放视频, 6s以上机型支持)

*    和 `PHAsset` 一样也是一个资源包, 不同的是他不仅包含了一张图片,而且还有一段mov格式的视频(拍摄该照片时前后几秒的视频)


*    PHCollection 有两个子类 `PHCollectionList` 和 `PHAssetCollection`



*    PHAssetCollection

*    由 `PHAsset` 组成的集合. 可以理解成一个相册

*    PHCollectionList

*    表示一组`PHAssetCollection`, 自己本身就是集合类型(可以理解为二维数组), 照片中的 `年度-精选-时刻` ,就是个 `PHCollectionList` 集合. 组`PHAssetCollection`, 自己本身就是集合类型(可以理解为二维数组), 照片中的 `年度-精选-时刻`中的 "年度","精选","时刻"就是PHAssetCollection类型(一维数组)

*    PHImageManager

*    请求图片, 视频以及LivePhoto
* `PHImageRequestOptions`, `PHLivePhotoRequestOptions`, `PHVideoRequestOptions` 分别负责请求图片, LivePhoto和视频的请求参数的配置(例如图片大小)
* `PHCachingImageManager`:负责缓存, 当有大量图片要加载时, 它将图片预加载到内存中

* PHFetchResult 请求结果集合

*    PHChange: 负责变化一定要注意不论是collection还是asset对象在变化之前都要检验他们能否改变, 通过 `canPerformEditOperation` 方法检验即可

*    当你使用PHPhotoLibrary添加监听之后, 你可以传入一个PHObject或者PHFetchResult对象给PHChange来监听他们的变化
* PHObjectChangeDetails,PHFetchResultChangeDetails分别监听PHObject和PHFetchResult变化

*    PHAssetChangeRequest

*    负责创建, 删除, 修改资源(PHAsset)
* 只能在[PHPhotoLibrary performChanges:] 或者[PHPhotoLibrary performChangesAndWait:]的block中使用
* PHContentEditingInput:对照片进行编辑时作为输入, PHContentEditingInputRequestOptions:对照片编辑时输入照片的参数设置, PHContentEditingOutput: 照片编辑完成之后的输出, PHAdjustmentData: 保存照片编辑过程中的数据, 方便撤回和修改照片的编辑数据.

*    PHAssetCreationRequest: 创建PHAsset对象,<mark>并将其保存在照片库中</mark>


* PHAssetCollectionChangeRequest

*    负责资源集合创建, 删除, 修改资源(PHAssetCollection),例如在某个集合中增删改查移等操作

* PHAssetResource

*    负责将PHAsset资源转化成资源文件(PHAssetResource)
*     它是一种中间产物, 能通过PHAssetResourceManager将其转换成Data, 用于上传服务器

//将PHAsset转化成PHAssetResource对象
+ (NSArray<PHAssetResource *> *)assetResourcesForAsset:(PHAsset *)asset;

----------

//将PHLivePhoto转化成PHAssetResource对象
+ (NSArray<PHAssetResource *> *)assetResourcesForLivePhoto:(PHLivePhoto *)livePhoto PHOTOS_AVAILABLE_IOS_TVOS(9_1, 10_0);



* PHAssetResourceManager

*    负责将PHAssetResource资源转化成真正的图片或者视频文件, 用于上传服务器

//将较小PHAssetResource对象(图片或者短视频)转化成NSData类型, 用来上传服务器, 或其他操作
//此方法一般用于转化较小的PHAssetResource对象, 如果太大内存会暴涨, 大文件一般用下面哪个方法
-(PHAssetResourceDataRequestID)requestDataForAssetResource:(PHAssetResource *)resource
options:(nullable PHAssetResourceRequestOptions *)options
dataReceivedHandler:(void (^)(NSData *data))handler
completionHandler:(void(^)(NSError *__nullable error))completionHandler;


---------------

//将较大PHAssetResource对象(视频)转化成NSData类型, 并保存到本地, 用来从本地将资源上传服务器, 或其他操作
-(void)writeDataForAssetResource:(PHAssetResource *)resource
toFile:(NSURL *)fileURL
options:(nullable PHAssetResourceRequestOptions *)options
completionHandler:(void(^)(NSError *__nullable error))completionHandler;

-------------

//取消转化
- (void)cancelDataRequest:(PHAssetResourceDataRequestID)requestID;





#### 使用案例一:

下面以一个常见的使用场景进行 PHAsset 操作过程的描述：
从相册选择图片或视频 — 将图片或视频上传 CDN — 下载图片或视频 — 将图片或视频保存到相册


2.从相册选择图片 Asset 或视频 Asset

UIImagePickerController 是从相册选取图片 Asset 和视频 Asset 的选择器，利用其进行图片和视频选择结束之后会通过其代理（实现了 UIImagePickerControllerDelegate 协议）执行下面的方法, 将选择结果返回给用户。

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info;
从上面的接口看到，选择回来的仅仅是 info 信息，PHAsset 需要利用 info 字典的信息进一步获得。info 字典例子：

//选择的是图片
info{
UIImagePickerControllerMediaType = "public.image";
UIImagePickerControllerOriginalImage = "<UIImage: 0x126cacc60> size {2048, 1365} orientation 0 scale 1.000000";
UIImagePickerControllerReferenceURL = "assets-library://asset/asset.PNG?i/../B&ext=PNG";
}

//选择的是视频
info{
UIImagePickerControllerMediaType = "public.movie";
UIImagePickerControllerMediaURL = "file:///private/../BD-E6D273D5B376.MOV";
UIImagePickerControllerReferenceURL = "assets-library://asset/asset.MOV?id=546/../B&ext=MOV";
}

//选择的是 LivePhoto
info{
UIImagePickerControllerLivePhoto = "<PHLivePhoto: 0x126e3a170>";
UIImagePickerControllerMediaType = "com.apple.live-photo";
UIImagePickerControllerOriginalImage = "<UIImage: 0x126c56b10> size {960, 1280} orientation 0 scale 1.000000";
UIImagePickerControllerReferenceURL = "assets-library://asset/asset.JPG?id/../B3&ext=JPG";
}
从 info 字典的例子可以看到，选择图片，视频和 LivePhoto 三种的回调信息是有区别的，每个结果包含的字段也不相同，但是都有个 UIImagePickerControllerReferenceURL 键值，顾名思义，assets-library 这条 URL 便是指向我们所选择的 PHAsset 对象的 URL。

Fetching Assets: 从 assets-library URL 获取我们需要的图片和视频 Asset

NSURL *url = [info objectForKey:@"UIImagePickerControllerReferenceURL"];
PHFetchResult *fetchResult = [PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil];
PHAsset *asset = fetchResult.firstObject;
Reading Asset Metadata: PHAsset 对象仅仅包含文件的基本数据 (Assets contain only metadata) 。

这些基本信息包含：媒体属性 (mediaType)，资源类型 (sourceType)，图片像素长宽 (pixelWidth)，拍摄地点（location），视频播放时长 (duration) 等。我们下面的例子用到 mediaType 和 mediaSubtypes 两个属性来区分图片，视频和 LivePhoto 三种不同的 Asset。

3.将图片 Asset 或视频 Asset 转换为真正的文件

经过上面 Fetching Assets 步骤我们已经成功的从 assets-library url 提取出 PHAsset 对象。现在需要把 PHAsset 转换为真正的视频和图片文件。我们要获取的真正文件无非两种：图片文件和视频文件。上面示例涉及的三种 PHAsset，其中视频 Asset 和图片 Asset 可以分别提取视频和图片文件。LivePhoto Asset 既可以提取图片也可以提取视频。

从 PHAsset 获取图片：

+ (void)getImageFromPHAsset:(PHAsset *)asset Complete:(Result)result {
__block NSData *data;
PHAssetResource *resource = [[PHAssetResource assetResourcesForAsset:asset] firstObject];
if (asset.mediaType == PHAssetMediaTypeImage) {
PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
options.version = PHImageRequestOptionsVersionCurrent;
options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
options.synchronous = YES;
[[PHImageManager defaultManager] requestImageDataForAsset:asset
options:options
resultHandler:
^(NSData *imageData,
NSString *dataUTI,
UIImageOrientation orientation,
NSDictionary *info) {
data = [NSData dataWithData:imageData];
}];
}

if (result) {
if (data.length <= 0) {
result(nil, nil);
} else {
result(data, resource.originalFilename);
}
}
}
在上面的代码中我们通过判断 asset.mediaType == PHAssetMediaTypeImage 来区分 PHAsset 是否是一个图片类型的 Asset。值得注意的是 LivePhoto Asset 的 mediaType 属性值也等于 PHAssetMediaTypeImage，所以提取 LivePhoto 里面的图片也可以直接调用此方法。

既然 mediaType 属性一样，怎么才能具体区分一个 PHAsset 是图片 Asset 还是 LivePhoto 呢，答案是通过 PHAsset 的 mediaSubtypes 属性。

PHAsset 的媒体属性 （mediaType）和二级媒体属性（mediaSubtypes）：

typedef NS_ENUM(NSInteger, PHAssetMediaType) {
PHAssetMediaTypeUnknown = 0,
PHAssetMediaTypeImage   = 1,
PHAssetMediaTypeVideo   = 2,
PHAssetMediaTypeAudio   = 3,
} NS_ENUM_AVAILABLE_IOS(8_0);

typedef NS_OPTIONS(NSUInteger, PHAssetMediaSubtype) {
PHAssetMediaSubtypeNone               = 0,

// Photo subtypes
PHAssetMediaSubtypePhotoPanorama      = (1UL << 0),
PHAssetMediaSubtypePhotoHDR           = (1UL << 1),
PHAssetMediaSubtypePhotoScreenshot NS_AVAILABLE_IOS(9_0) = (1UL << 2),
PHAssetMediaSubtypePhotoLive NS_AVAILABLE_IOS(9_1) = (1UL << 3),

// Video subtypes
PHAssetMediaSubtypeVideoStreamed      = (1UL << 16),
PHAssetMediaSubtypeVideoHighFrameRate = (1UL << 17),
PHAssetMediaSubtypeVideoTimelapse     = (1UL << 18),
} N    S_AVAILABLE_IOS(8_0);

可以看到 PHAsset mediaType 可以区分图片，视频和音频。PhotoLive 属于 Photo 类型下面的一个 subtypes。

从 PHAsset 获取视频：

+ (void)getVideoFromPHAsset:(PHAsset *)asset Complete:(Result)result {
NSArray *assetResources = [PHAssetResource assetResourcesForAsset:asset];
PHAssetResource *resource;

for (PHAssetResource *assetRes in assetResources) {
if (assetRes.type == PHAssetResourceTypePairedVideo ||
assetRes.type == PHAssetResourceTypeVideo) {
resource = assetRes;
}
}
NSString *fileName = @"tempAssetVideo.mov";
if (resource.originalFilename) {
fileName = resource.originalFilename;
}

if (asset.mediaType == PHAssetMediaTypeVideo || asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
options.version = PHImageRequestOptionsVersionCurrent;
options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;

NSString *PATH_MOVIE_FILE = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
[[NSFileManager defaultManager] removeItemAtPath:PATH_MOVIE_FILE error:nil];
[[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource
toFile:[NSURL fileURLWithPath:PATH_MOVIE_FILE]
options:nil
completionHandler:^(NSError * _Nullable error) {
if (error) {
result(nil, nil);
} else {

NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:PATH_MOVIE_FILE]];
result(data, fileName);
}
[[NSFileManager defaultManager] removeItemAtPath:PATH_MOVIE_FILE  error:nil];
}];
} else {
result(nil, nil);
}
}


注：上面方法兼顾了从 LivePhoto 里面提取视频文件。

4.图片或视频文件上传 CDN

上面两段代码具体介绍了 PHAsset 到真正图片文件和视频文件的提取过程。既：可以简单里复用这两个方法来提取真正的 fileData。然后将 fileData 上传到 CDN 或者服务器。

typedef void(^Result)(NSData *fileData, NSString *fileName);
+ (void)getImageFromPHAsset:(PHAsset *)asset Complete:(Result)result;
+ (void)getVideoFromPHAsset:(PHAsset *)asset Complete:(Result)result;

值得注意的是：上述两个接口，最后回调结果是 fileData。对于图片 PHAsset，因为图片文件不会很大，所以直接拿到图片 data 是可以的。但是对于视频 PHAsset，视频文件较大会占用大量内存空间。 我们可以通过修改上面的接口，用视频的 filePath 来替代 fileData，以解决处理大文件视频情况下的内存占用问题。

修改接口，获取 videoFilePath，注意：使用完成，最好手动删除这个临时文件

typedef void(^ResultPath)(NSString *filePath, NSString *fileName);

+ (void)getVideoPathFromPHAsset:(PHAsset *)asset Complete:(ResultPath)result {
NSArray *assetResources = [PHAssetResource assetResourcesForAsset:asset];
PHAssetResource *resource;

for (PHAssetResource *assetRes in assetResources) {
if (assetRes.type == PHAssetResourceTypePairedVideo ||
assetRes.type == PHAssetResourceTypeVideo) {
resource = assetRes;
}
}
NSString *fileName = @"tempAssetVideo.mov";
if (resource.originalFilename) {
fileName = resource.originalFilename;
}

if (asset.mediaType == PHAssetMediaTypeVideo || asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
options.version = PHImageRequestOptionsVersionCurrent;
options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;

NSString *PATH_MOVIE_FILE = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
[[NSFileManager defaultManager] removeItemAtPath:PATH_MOVIE_FILE error:nil];
[[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource
toFile:[NSURL fileURLWithPath:PATH_MOVIE_FILE]
options:nil
completionHandler:^(NSError * _Nullable error) {
if (error) {
result(nil, nil);
} else {
result(PATH_MOVIE_FILE, fileName);
}
}];
} else {
result(nil, nil);
}
}

利用返回的 filePath 可以通过流式的读取文件方式，来组织和发送上传请求的 body 体，达到较好的内存占用。同时又拍云 CDN 提供文件分块上传接口，更适合这种大文件的上传操作。

5.下载图片和视频保存到手机相册

将图片文件和视频文件保存到手机相册需要以下两个方法：

void UIImageWriteToSavedPhotosAlbum(UIImage *image, id completionTarget, SEL completionSelector, void * contextInfo);
void UISaveVideoAtPathToSavedPhotosAlbum(NSString *videoPath, id completionTarget, SEL completionSelector, void * contextInfo);

那么如何保存 LivePhoto，对于支持 LivePhoto 的手机用户可能需要将 LivePhoto 保存到手机相册。但是事实上 LivePhoto 不能作为一个整体文件存在于内存硬盘或者服务器。但是可以将一个视频文件和图片文件一起作为 LivePhoto Asset 保存到相册：

保存 LivePhoto 代码示例：

NSURL *photoURL = [NSURL fileURLWithPath:photoURLstring];//@"...picture.jpg"
NSURL *videoURL = [NSURL fileURLWithPath:videoURLstring];//@"...video.mov"

[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
[request addResourceWithType:PHAssetResourceTypePhoto
fileURL:photoURL
options:nil];
[request addResourceWithType:PHAssetResourceTypePairedVideo
fileURL:videoURL
options:nil];

} completionHandler:^(BOOL success,
NSError * _Nullable error) {
if (success) {
[self alertMessage:@"LivePhotos 已经保存至相册!"];

} else {
NSLog(@"error: %@",error);
}
}];
6.最后

ALAsset/PHAsset 是属于 iPhone 相册相关操作范围内的概念，ALAsset/PHAsset 并不是文件，不能直接上传 CDN。上传 CDN 需要的真正图片视频文件可以用上文提供的方法从 PHAsset 提取出来。 LivePhoto 属于一种特殊的 PHAsset，可以从 LivePhoto 里面分别提取图片和视频文件之后，再上传 CDN。
