//
//  HLLPhotoAccessor.m
//  Photos
//
//  Created by  bochb on 2018/1/10.
//  Copyright © 2018年 boc. All rights reserved.
//

#import "HLLPhotoAccessor.h"

@implementation HLLPhotoAccessor


/**
  获取自定义相册

 @param name 自定义相册名
 @param type 类型自定义相册类型还是相机胶卷类型
 @return 相册
 */
+ (PHAssetCollection *)getAssetCollectionWith:(NSString *)name type:(HLLAlbumType)type{
    
    PHAssetCollectionType collectionType;
    switch (type) {
        case HLLAlbumTypeCamera:
            collectionType = PHAssetCollectionTypeSmartAlbum;
            break;
            case HLLAlbumTypeCustom:
            collectionType = PHAssetCollectionTypeAlbum;
            break;
            case HLLAlbumTypeAny:
             collectionType = PHAssetCollectionTypeAlbum;
            break;
    }
    // 先从已存在相册中找到自定义相册对象
    
    PHFetchResult<PHAssetCollection *> *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:collectionType subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collectionResult) {
        NSLog(@"%@",collection.localizedTitle);
        if ([collection.localizedTitle isEqualToString:name]) {
            return collection;
        }
    }
    return nil;
}


/**
 同步创建一个相册并返回
 
 @param name 相册名
 @return 创建成功的相册对象, 为nil则表示创建失败
 */

+ (PHAssetCollection *)creatAssetCollectionNamed:(NSString *)name {
    //相册ID
    __block NSString *collectionId = nil;
    NSError *error = nil;
    //同步创建一个相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        //创建并记录id
        collectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:name].placeholderForCreatedAssetCollection.localIdentifier;
    } error:&error];
    
    if (error) {
        NSLog(@"获取相册【%@】失败", name);
        return nil;
    }
    //根据id获取自定义相册
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil].lastObject;
}

/**
 异步创建一个相册并返回(异步可以自己用GCD实现)
 
 @param name 相册名
 */
//+ (void)creatAssetCollectionNamed:(NSString *)name completionHandler:(void(^)(PHAssetCollection * assetCollection, NSError *error))completionHandler{
//    //相册ID
//    __block NSString *collectionId = nil;
//    //同步创建一个相册
//    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//        //创建并记录id
//        collectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:name].placeholderForCreatedAssetCollection.localIdentifier;
//    } completionHandler:^(BOOL success, NSError * _Nullable error) {
//
//        if (success) {
//            completionHandler([PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil].lastObject, nil);
//        }else{
//            completionHandler(nil, error);
//        }
//
//    }];
//}

/**
 存储图片到对应名称的相册中

 @param image 图片
 @param assetCollectionName 相册名称
 @param flag 如果相册不存在是否创建
 @return 返回一个PHObjectPlaceholder对象, 可以通过此对象的localIdentifier属性(图片在相册中的唯一标示符)找到此图片对象对应的PHAsset
 */
+ (PHObjectPlaceholder *)saveImage:(UIImage *)image inAssetCollectionNamed:(NSString *)assetCollectionName creatCollectionIfNone:(BOOL)flag{
    if (!image) {
        return nil;
    }
    if (!assetCollectionName) {
        return [HLLPhotoAccessor saveImage:image inAssetCollection:nil];
    }
    PHAssetCollection *collection = [HLLPhotoAccessor getAssetCollectionWith:assetCollectionName type:HLLAlbumTypeAny];
    if (!collection) {
        //没有相册
        if (!flag) {
            return nil;
        }
       collection = [HLLPhotoAccessor creatAssetCollectionNamed:assetCollectionName];
    }
    return [HLLPhotoAccessor saveImage:image inAssetCollection:collection];
}


/**
 通过UIImage对象创建PHAsset对象

 @param image 图片对象
 @return 返回的是PHObjectPlaceholder, 他是PHAsset的父类
 */
+ (PHObjectPlaceholder *)creatAssetWithImage:(UIImage *)image{
    NSError *error = nil;
    
    // 创建PHAsset对象
    __block PHObjectPlaceholder *objectPlaceholder = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
       objectPlaceholder = [PHAssetChangeRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset;
    } error:&error];
    
    if (error) {
        NSLog(@"保存失败：%@", error);
        return nil;
    }
    return objectPlaceholder;
}

/**
 保存图片到指定相册

 @param image 要保存的图片
 @param assetCollection 保存目标相册, nil 则保存到Camera Roll中
 @return 返回一个PHObjectPlaceholder对象, 可以通过此对象的localIdentifier属性(图片在相册中的唯一标示符)找到此图片对象对应的PHAsset
 */
+ (PHObjectPlaceholder *)saveImage:(UIImage *)image inAssetCollection:(PHAssetCollection *)assetCollection {
    // 判断授权状态
    
    if (!image) {
        //NSLog(@"保存的图片为空");
        return nil;
    }
    if (assetCollection == nil){
        return [HLLPhotoAccessor saveImage:image];
    }
    NSError *error = nil;
    
    // 从image创建PHAsset对象
    PHObjectPlaceholder *objectPlaceholder = [HLLPhotoAccessor creatAssetWithImage:image];

    //在自定义相册中插入图片
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        [[PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection] insertAssets:@[objectPlaceholder] atIndexes:[NSIndexSet indexSetWithIndex:0]];
    } error:&error];
    
    if (error) {
        NSLog(@"保存失败：%@", error);
        return nil;
    }
    return objectPlaceholder;
}


/**
 保存相片到照片库的相机胶卷中(Camera Roll)

 @param image 要保存的图片
 @return 返回一个PHObjectPlaceholder对象, 可以通过此对象的localIdentifier属性(图片在相册中的唯一标示符)找到此图片对象对应的PHAsset
 */
+ (PHObjectPlaceholder *)saveImage:(UIImage *)image{
    if (image == nil) {
        return nil;
    }
    NSError *error = nil;
    // 保存相片到相机胶卷
    __block PHObjectPlaceholder *objectPlaceholder = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        objectPlaceholder = [PHAssetCreationRequest creationRequestForAssetFromImage:image].placeholderForCreatedAsset;
    } error:&error];
    
    if (error) {
        NSLog(@"保存失败：%@", error);
        return nil;
    }
    return objectPlaceholder;
}

- (PHObjectPlaceholder *)saveVidoeFromURL:(NSURL *)fileURL {
    __block PHObjectPlaceholder *objectPlaceholder = nil;
    NSError *error;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        objectPlaceholder = [PHAssetCreationRequest creationRequestForAssetFromVideoAtFileURL:fileURL].placeholderForCreatedAsset;
    } error:&error];
    if (error) {
        NSLog(@"%@",error);
        return nil;
    }
    return objectPlaceholder;
}
/**
 删除某个相册中的图片
 
 @param assetCollectionName 相册
 @param indexes 要删除的图片索引集, nil则删除第一张
 @return 删除结果
 */
+ (BOOL)deleteAssetsFromAssetCollectionNamed:(NSString *)assetCollectionName at:(NSIndexSet *_Nullable)indexes{
    if (assetCollectionName == nil) {
        return false;
    }
    return [HLLPhotoAccessor deleteAssetsFromAssetCollection:[HLLPhotoAccessor getAssetCollectionWith:assetCollectionName type:HLLAlbumTypeCustom] at:indexes];
}

/**
 删除某个相册中的图片

 @param assetCollection 相册
 @param indexes 要删除的图片索引集, nil则删除第一张
 @return 删除结果
 */
+ (BOOL)deleteAssetsFromAssetCollection:(PHAssetCollection *)assetCollection at:(nullable NSIndexSet *)indexes{

        //找到自定义相册
    //如果传入相册为空, 就删除Camera Roll里的图片
    if (assetCollection == nil){
        return false;
    }

        NSLog(@"%@",assetCollection.localizedTitle);
    
        NSError *error;
       BOOL res = [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
            
            if (assetCollection.estimatedAssetCount == 0) {//相册没有图片
                return;
            }
           [[PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection] removeAssetsAtIndexes: !indexes ? [NSIndexSet indexSetWithIndex:0] : indexes];
        } error:&error];
        
        if (error) {
            NSLog(@"删除失败：%@", error);
            return false;
        }
    return res;
    
}




/**
 根据照片的唯一标示符删除照片
 
 @param identifiers 唯一标示符数组
 @param options 从标示符数组中查询符合要求的配置
 @return 结果
 */
+ (BOOL)deleteAssetsWithLocalIdentifiers:(NSArray <NSString *>*)identifiers options:(PHFetchOptions *)options {
    NSError *error;
    PHFetchResult <PHAsset *>* result = [PHAsset fetchAssetsWithLocalIdentifiers:identifiers options:options];
    if (result.count == 0) {
        NSLog(@"照片不存在");
        return YES;
    }
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        [PHAssetChangeRequest deleteAssets:result];
    } error:&error];
    
    if (error) {
        NSLog(@"%@",error);
        return NO;
    }
    return YES;
}

/**
 * 查询某个相册里面的所有图片
 */
+ (void)fetchImagesInCollection:(PHAssetCollection *)collection handler:(void(^)(NSArray *images))handler {
   
    // 采取同步获取图片（只获得一次图片）
    PHImageRequestOptions *imageOptions = [[PHImageRequestOptions alloc] init];
 
    imageOptions.synchronous = YES;
    
    NSLog(@"相册名字：%@", collection.localizedTitle);
    
    // 遍历这个相册中的所有图片
    PHFetchResult<PHAsset *> *assetResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
    for (PHAsset *asset in assetResult) {
        // 过滤非图片
        if (asset.mediaType != PHAssetMediaTypeImage) continue;
        
        // 图片原尺寸
        CGSize targetSize = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
        // 请求图片
        [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeDefault options:imageOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
             NSMutableArray *imgs = [NSMutableArray array];
//            dispatch_async(dispatch_get_main_queue(), ^{
                if (result != nil) {
                    [imgs addObject:result];
                }
                //结果
//            });
            if (handler) {
                handler(imgs.copy);
            }
        }];
     
    }
}

/**
 查询所有图片

 @param handler 查询结果
 */
+ (void)fetchAllImagesWithHandler:(void(^)(NSArray *images))handler {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) return;
        //此时在子线程中, 更新UI一定要回到主线程
        // 获得相机胶卷的图片
       __block NSMutableArray *imagesArr = [NSMutableArray array];
        PHFetchResult<PHAssetCollection *> *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
        for (PHAssetCollection *collection in collectionResult) {
            NSLog(@"%@",collection);
            if (![collection.localizedTitle isEqualToString:@"Camera Roll"]) {
                continue;
            }
            [HLLPhotoAccessor fetchImagesInCollection:collection handler:^(NSArray *images) {
                for (UIImage *image in images) {
                    [imagesArr addObject:image];
                }
            }];
            break;
        }
            
        });
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (handler) {
                handler(imagesArr);
            }
        });
    }];
}


/**
 移动某个相册中的对象

 @param collection 相册对象
 @param fromIndexes 起始
 @param toIndex 结束
 @return 结果
 */
+ (BOOL)moveAssetsInAssetCollectionNamed:(PHAssetCollection *)collection AtIndexes:(NSIndexSet *)fromIndexes toIndex:(NSUInteger)toIndex{
//    PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
//    __block PHAssetCollection * collection = nil;
//
//    [result enumerateObjectsUsingBlock:^(PHAssetCollection *obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        NSLog(@"%@",obj.localizedTitle);
//        if ([obj.localizedTitle isEqualToString:@"Camera Roll"]) {
//            collection = obj;
//        }
//    }];
    //判断collection有没有相应的操作权限
    if (![collection canPerformEditOperation:PHCollectionEditOperationRearrangeContent]) {
        NSLog(@"没有移动权限");
        return NO;
    }
    NSError *error;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        [[PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection] moveAssetsAtIndexes:fromIndexes toIndex:toIndex];
    } error:&error];
    if (error) {
        NSLog(@"%@",error);
        return NO;
    }
    return YES;
}
@end
