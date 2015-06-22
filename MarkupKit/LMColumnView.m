//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "LMColumnView.h"
#import "UIView+Markup.h"

#define DEFAULT_ALIGNMENT LMBoxViewAlignmentFill

@implementation LMColumnView

- (instancetype)initWithFrame:(CGRect)frame
{
    return [super initWithFrame:frame alignment:DEFAULT_ALIGNMENT];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    return [super initWithCoder:decoder alignment:DEFAULT_ALIGNMENT];
}

- (void)setAlignment:(LMBoxViewAlignment)alignment
{
    NSAssert(alignment == LMBoxViewAlignmentLeft
        || alignment == LMBoxViewAlignmentRight
        || alignment == LMBoxViewAlignmentLeading
        || alignment == LMBoxViewAlignmentTrailing
        || alignment == LMBoxViewAlignmentCenter
        || alignment == LMBoxViewAlignmentFill, @"Invalid alignment.");

    [super setAlignment:alignment];
}

- (CGSize)intrinsicContentSize
{
    CGSize size;
    if ([self alignment] == LMBoxViewAlignmentFill) {
        size = [super intrinsicContentSize];
    } else {
        size = CGSizeMake(0, 0);

        NSArray *arrangedSubviews = [self arrangedSubviews];

        for (UIView * subview in arrangedSubviews) {
            CGSize subviewSize = [subview intrinsicContentSize];

            if (subviewSize.width != UIViewNoIntrinsicMetric) {
                size.width = MAX(size.width, subviewSize.width);
            }

            if (subviewSize.height != UIViewNoIntrinsicMetric) {
                size.height += subviewSize.height;
            }
        }

        UIEdgeInsets layoutMargins = [self layoutMargins];

        size.width += layoutMargins.left + layoutMargins.right;
        size.height += layoutMargins.top + layoutMargins.bottom + ([arrangedSubviews count] - 1) * [self spacing];
    }

    return size;
}

- (void)layoutSubviews
{
    // Ensure that subviews resize according to weight
    UILayoutPriority horizontalPriority = ([self alignment] == LMBoxViewAlignmentFill) ? UILayoutPriorityDefaultLow : UILayoutPriorityDefaultHigh;

    for (UIView * subview in [self arrangedSubviews]) {
        [subview setContentCompressionResistancePriority:horizontalPriority forAxis:UILayoutConstraintAxisHorizontal];
        [subview setContentHuggingPriority:horizontalPriority forAxis:UILayoutConstraintAxisHorizontal];

        UILayoutPriority verticalPriority = isnan([subview weight]) ? UILayoutPriorityRequired : UILayoutPriorityDefaultLow;

        [subview setContentCompressionResistancePriority:verticalPriority forAxis:UILayoutConstraintAxisVertical];
        [subview setContentHuggingPriority:verticalPriority forAxis:UILayoutConstraintAxisVertical];
    }

    [super layoutSubviews];
}

- (NSArray *)createConstraints
{
    NSMutableArray *constraints = [NSMutableArray new];

    LMBoxViewAlignment alignment = [self alignment];
    CGFloat spacing = [self spacing];

    UIView *previousSubview = nil;
    UIView *previousWeightedSubview = nil;

    for (UIView *subview in [self arrangedSubviews]) {
        // Align to siblings
        if (previousSubview == nil) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTop
                relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTopMargin
                multiplier:1 constant:0]];
        } else {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTop
                relatedBy:NSLayoutRelationEqual toItem:previousSubview attribute:NSLayoutAttributeBottom
                multiplier:1 constant:spacing]];
        }

        CGFloat weight = [subview weight];

        if (!isnan(weight)) {
            if (previousWeightedSubview != nil) {
                [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeHeight
                    relatedBy:NSLayoutRelationEqual toItem:previousWeightedSubview attribute:NSLayoutAttributeHeight
                    multiplier:weight / [previousWeightedSubview weight] constant:0]];
            }

            previousWeightedSubview = subview;
        }

        // Align to parent
        if (alignment == LMBoxViewAlignmentLeft) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeft
                relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeftMargin
                multiplier:1 constant:0]];
        } else if (alignment == LMBoxViewAlignmentRight) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeRight
                relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRightMargin
                multiplier:1 constant:0]];
        } else if (alignment == LMBoxViewAlignmentLeading) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeading
                relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeadingMargin
                multiplier:1 constant:0]];
        } else if (alignment == LMBoxViewAlignmentTrailing) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTrailing
                relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailingMargin
                multiplier:1 constant:0]];
        } else if (alignment == LMBoxViewAlignmentCenter) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeCenterX
                relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX
                multiplier:1 constant:0]];
        } else if (alignment == LMBoxViewAlignmentFill) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeft
                relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeftMargin
                multiplier:1 constant:0]];
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeRight
                relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRightMargin
                multiplier:1 constant:0]];
        } else {
            [NSException raise:NSInternalInconsistencyException format:@"Unexpected horizontal alignment."];
        }

        previousSubview = subview;
    }

    // Align final view to bottom edge
    if (previousSubview != nil) {
        [constraints addObject:[NSLayoutConstraint constraintWithItem:previousSubview attribute:NSLayoutAttributeBottom
            relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeBottomMargin
            multiplier:1 constant:0]];
    }

    return constraints;
}

@end