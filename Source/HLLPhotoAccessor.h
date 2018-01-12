//
//  HLLPhotoAccessor.h
//  Photos
//
//  Created by  bochb on 2018/1/10.
//  Copyright © 2018年 boc. All rights reserved.
//

//1, 保存相册到camera roll
//2, livePhoto的操作
//3,选取并上传图片, 视频和livephoto

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

typedef NS_ENUM(NSInteger, HLLAlbumType){
    HLLAlbumTypeCustom,//自定义相册
    HLLAlbumTypeCamera,//相机胶卷
    HLLAlbumTypeAny//查询所有
};

@interface HLLPhotoAccessor : NSObject
/**
 创建一个相册并返回
 
 @param name 相册名
 @return 创建成功的相册对象, 为nil则表示创建失败
 */
+ (PHAssetCollection *_Nullable)creatAssetCollectionNamed:(NSString *_Nonnull)name;

/**
 通过UIImage对象创建PHAsset对象
 
 @param image 图片对象
 @return 返回的是PHObjectPlaceholder, 他是PHAsset的父类
 */
+ (PHObjectPlaceholder *_Nullable)creatAssetWithImage:(UIImage *_Nonnull)image;

/**
 获取自定义相册
 
 @param name 自定义相册名
 @param type 类型自定义相册类型还是相机胶卷类型
 @return 相册
 */
+ (PHAssetCollection *_Nullable)getAssetCollectionWith:(NSString *_Nullable)name type:(HLLAlbumType)type;

/**
 * 查询某个相册里面的所有图片
 */
+ (void)fetchImagesInCollection:(PHAssetCollection *_Nullable)collection handler:(void(^_Nullable)(NSArray * _Nonnull images))handler;


/**
 查询所有图片
 
 @param handler 查询结果
 */
+ (void)fetchAllImagesWithHandler:(void(^_Nullable)(NSArray * _Nullable images))handler;



/**
 存储图片到对应名称的相册中
 
 @param image 图片
 @param assetCollectionName 相册名称
 @param flag 如果相册不存在是否创建
 @return 结果
 */
+ (PHObjectPlaceholder *_Nullable)saveImage:(UIImage *_Nonnull)image inAssetCollectionNamed:(NSString *_Nullable)assetCollectionName creatCollectionIfNone:(BOOL)flag;

/**
 保存图片到指定相册
 
 @param image 要保存的图片
 @param assetCollection 保存目标相册, nil 则保存到Camera Roll中
 @return 返回一个PHObjectPlaceholder对象, 可以通过此对象的localIdentifier属性(图片在相册中的唯一标示符)找到此图片对象对应的PHAsset
 */
+ (PHObjectPlaceholder *_Nullable)saveImage:(UIImage *_Nonnull)image inAssetCollection:(PHAssetCollection *_Nullable)assetCollection;

/**
 保存相片到照片库的相机胶卷中(Camera Roll)
 
 @param image 要保存的图片
 @return 返回一个PHObjectPlaceholder对象, 可以通过此对象的localIdentifier属性(图片在相册中的唯一标示符)找到此图片对象对应的PHAsset
 */
+ (PHObjectPlaceholder *_Nullable)saveImage:(UIImage *_Nullable)image;


/**
 删除某个相册中的图片
 
 @param assetCollectionName 相册
 @param indexes 要删除的图片索引集, nil则删除第一张
 @return 删除结果
 */
+ (BOOL)deleteAssetsFromAssetCollectionNamed:(NSString *_Nonnull)assetCollectionName at:(NSIndexSet *_Nullable)indexes;

/**
 删除某个相册中的图片
 
 @param assetCollection 相册, nil从camera roll中删除
 @param indexes 要删除的图片索引集, nil则删除第一张
 @return 删除结果
 */
+ (BOOL)deleteAssetsFromAssetCollection:(PHAssetCollection *_Nonnull)assetCollection at:(NSIndexSet *_Nullable)indexes;


/**
 根据照片的唯一标示符删除照片
 
 @param identifiers 唯一标示符数组
 @param options 从标示符数组中查询符合要求的配置
 @return 结果
 */
+ (BOOL)deleteAssetsWithLocalIdentifiers:(NSArray <NSString *>*_Nonnull)identifiers options:(PHFetchOptions *_Nullable)options;




#pragma mark - 增删改查暂时不写, 很简单, 依照这个例子即可
/**
 移动某个相册中的对象
 
 @param collection 相册对象
 @param fromIndexes 起始
 @param toIndex 结束
 @return 结果
 */
+ (BOOL)moveAssetsInAssetCollectionNamed:(PHAssetCollection *_Nonnull)collection AtIndexes:(NSIndexSet *_Nonnull)fromIndexes toIndex:(NSUInteger)toIndex;

@end
