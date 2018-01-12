//
//  ViewController.m
//  Photos
//
//  Created by  bochb on 17/2/6.
//  Copyright © 2017年 boc. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
#import "HLLPhotoAccessor.h"

static NSString *XMGCollectionName = @"新建相册1";

@interface ViewController ()<UICollectionViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UICollectionViewFlowLayout *flowLayout;


@property (nonatomic, strong) NSMutableArray <UIImage *>*images;

@property (nonatomic, strong) __block PHObjectPlaceholder *placeHolder;
@end

@implementation ViewController

static NSString *cellId = @"cellId";

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:cellId];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    CGFloat margin = 10.0;
    int colum = 4;
    CGFloat itemWidth = (self.view.bounds.size.width - margin * (colum - 1)) / colum;
    self.flowLayout.itemSize = CGSizeMake(itemWidth, itemWidth);
    self.flowLayout.minimumLineSpacing = margin;
    self.flowLayout.minimumInteritemSpacing = margin;
    self.flowLayout.headerReferenceSize = CGSizeMake(self.view.bounds.size.width, 44);
}
//查询相册, 包括查询所有相册和查询某个相册
- (IBAction)checkAll:(id)sender {
    _images = nil;
//    [self searchImages];
  
    [HLLPhotoAccessor fetchAllImagesWithHandler:^(NSArray *images) {
        self.images = images;
        [self.collectionView reloadData];
    }];
}

- (IBAction)checkOneCollection:(id)sender {
//    [self collection];
    PHAssetCollection *collection = [HLLPhotoAccessor getAssetCollectionWith:@"Camera Roll" type:HLLAlbumTypeCamera];
    NSLog(@"%@",collection.localizedTitle);
    
}
- (IBAction)save:(id)sender {
    [HLLPhotoAccessor saveImage:[UIImage imageNamed:@"infoDefault"] inAssetCollectionNamed:XMGCollectionName creatCollectionIfNone:YES];
}

//移动
- (void)textMove{
    PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    __block PHAssetCollection * collection = nil;
    
    [result enumerateObjectsUsingBlock:^(PHAssetCollection *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"%@",obj.localizedTitle);
        if ([obj.localizedTitle isEqualToString:@"Camera Roll"]) {
            collection = obj;
        }
    }];
    
    if (![collection canPerformEditOperation:PHCollectionEditOperationRearrangeContent]) {
        NSLog(@"没有操作权限");
        return;
    }
    NSError *error;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        [[PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection] moveAssetsAtIndexes:[NSIndexSet indexSetWithIndex:0] toIndex:1];
    } error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
}

- (IBAction)delete:(id)sender {
//     [self deleteImage];
    [HLLPhotoAccessor deleteAssetsFromAssetCollectionNamed:@"Camera Roll" at:nil];
   

}
#pragma mark - 查询某个相册里面的所有图片
/**
 * 查询某个相册里面的所有图片, 此方法已经抽取到HLLPhotoAccessor中
 */
- (void)searchAllImagesInCollection:(PHAssetCollection *)collection{
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
           
            if (result != nil) {
                [self.images addObject:result];
            }
        }];
    }
}

#pragma mark - 保存图片到自定义相册
/**
 * 获取一个相册, 如果获取不到就新建一个, 并返回这个相册
 */
- (PHAssetCollection *)collection{
    // 先从已存在相册中找到自定义相册对象
    PHFetchResult<PHAssetCollection *> *collectionResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in collectionResult) {
        if ([collection.localizedTitle isEqualToString:XMGCollectionName]) {
            return collection;
        }
    }
    
    // 找不到 新建自定义相册
    //相册ID
    __block NSString *collectionId = nil;
    NSError *error = nil;
    //同步创建一个相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        //创建并记录id
        collectionId = [PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:XMGCollectionName].placeholderForCreatedAssetCollection.localIdentifier;
    } error:&error];
    
    if (error) {
        NSLog(@"获取相册【%@】失败", XMGCollectionName);
        return nil;
    }
    //根据id获取自定义相册
    return [PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil].lastObject;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/**
 * 保存图片到相册
 */
- (IBAction)saveImage {
    // 判断授权状态
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = nil;
            
            // 保存相片到相机胶卷
            __block PHObjectPlaceholder *createdAsset = nil;
            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                createdAsset = [PHAssetCreationRequest creationRequestForAssetFromImage:[UIImage imageNamed:@"屏幕快照 2017-02-06 上午9.36.23"]].placeholderForCreatedAsset;
                NSLog(@"%@", createdAsset);
            } error:&error];
            
            if (error) {
                NSLog(@"保存失败：%@", error);
                return;
            }
            
            // 拿到自定义的相册对象
            PHAssetCollection *collection = [self collection];
            if (collection == nil) return;
            
            //在自定义相册中插入图片
            [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
                [[PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection] insertAssets:@[createdAsset] atIndexes:[NSIndexSet indexSetWithIndex:0]];
            } error:&error];
            
            if (error) {
                NSLog(@"保存失败：%@", error);
            } else {
                NSLog(@"保存成功");
            }
        });
    }];
}
- (void)deleteImage{
//     __block NSError *error = nil;
//    __block PHObjectPlaceholder *obj = nil;
   //找到自定义相册
    PHAssetCollection *collection = [self collection];
    NSLog(@"%@",collection.localizedTitle);
    if (collection == nil) {//没找到相册
        return;
    }
    NSError *error;
    [[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
        
        if (collection.estimatedAssetCount == 0) {//相册没有图片
            return ;
        }
        [[PHAssetCollectionChangeRequest changeRequestForAssetCollection:collection] removeAssetsAtIndexes:[NSIndexSet indexSetWithIndex:0]];
    } error:&error];
    
    if (error) {
        NSLog(@"删除失败：%@", error);
        return;
    }
    
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return self.images.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    UIImageView *imgV = [[UIImageView alloc] initWithFrame:cell.bounds];
    imgV.image = self.images[indexPath.row];
    [cell.contentView addSubview: imgV];
    return cell;
}

- (NSMutableArray<UIImage *> *)images{
    if (!_images) {
        _images = [NSMutableArray array];
    }
    return _images;
}
@end
