//
//  NCDBEufeItem+CoreDataProperties.h
//  Neocom
//
//  Created by Артем Шиманский on 07.12.15.
//  Copyright © 2015 Artem Shimanski. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "NCDBEufeItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface NCDBEufeItem (CoreDataProperties)

@property (nullable, nonatomic, retain) NCDBEufeItemCategory *charge;
@property (nullable, nonatomic, retain) NCDBEufeItemDamage *damage;
@property (nullable, nonatomic, retain) NSSet<NCDBEufeItemGroup *> *groups;
@property (nullable, nonatomic, retain) NCDBEufeItemRequirements *requirements;
@property (nullable, nonatomic, retain) NCDBEufeItemShipResources *shipResources;
@property (nullable, nonatomic, retain) NCDBInvType *type;

@end

@interface NCDBEufeItem (CoreDataGeneratedAccessors)

- (void)addGroupsObject:(NCDBEufeItemGroup *)value;
- (void)removeGroupsObject:(NCDBEufeItemGroup *)value;
- (void)addGroups:(NSSet<NCDBEufeItemGroup *> *)values;
- (void)removeGroups:(NSSet<NCDBEufeItemGroup *> *)values;

@end

NS_ASSUME_NONNULL_END
