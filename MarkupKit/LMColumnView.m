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
#import "LMRowView.h"
#import "UIView+Markup.h"

@implementation LMColumnView

- (void)setAlignToGrid:(BOOL)alignToGrid
{
    _alignToGrid = alignToGrid;

    [self setNeedsUpdateConstraints];
}

- (void)setTopSpacing:(CGFloat)topSpacing
{
    _topSpacing = topSpacing;

    [self invalidateIntrinsicContentSize];
    [self setNeedsUpdateConstraints];
}

- (void)setBottomSpacing:(CGFloat)bottomSpacing
{
    _bottomSpacing = bottomSpacing;

    [self invalidateIntrinsicContentSize];
    [self setNeedsUpdateConstraints];
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

        CGFloat spacing = [self spacing];

        NSUInteger i = 0;

        for (UIView *subview in [self arrangedSubviews]) {
            if ([subview isHidden]) {
                continue;
            }

            if (i > 0) {
                size.height += spacing;
            }

            CGSize subviewSize = [subview intrinsicContentSize];

            if (subviewSize.width != UIViewNoIntrinsicMetric) {
                size.width = MAX(size.width, subviewSize.width);
            }

            if (subviewSize.height != UIViewNoIntrinsicMetric) {
                size.height += subviewSize.height;
            }

            i++;
        }

        if ([self layoutMarginsRelativeArrangement]) {
            UIEdgeInsets layoutMargins = [self layoutMargins];

            size.width += layoutMargins.left + layoutMargins.right;
            size.height += layoutMargins.top + layoutMargins.bottom;
        }

        size.height += _topSpacing + _bottomSpacing;
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

    NSLayoutAttribute topAttribute, bottomAttribute, leftAttribute, rightAttribute, leadingAttribute, trailingAttribute;
    if ([self layoutMarginsRelativeArrangement]) {
        topAttribute = NSLayoutAttributeTopMargin;
        bottomAttribute = NSLayoutAttributeBottomMargin;
        leftAttribute = NSLayoutAttributeLeftMargin;
        rightAttribute = NSLayoutAttributeRightMargin;
        leadingAttribute = NSLayoutAttributeLeadingMargin;
        trailingAttribute = NSLayoutAttributeTrailingMargin;
    } else {
        topAttribute = NSLayoutAttributeTop;
        bottomAttribute = NSLayoutAttributeBottom;
        leftAttribute = NSLayoutAttributeLeft;
        rightAttribute = NSLayoutAttributeRight;
        leadingAttribute = NSLayoutAttributeLeading;
        trailingAttribute = NSLayoutAttributeTrailing;
    }

    UIView *previousSubview = nil;
    UIView *previousWeightedSubview = nil;

    for (UIView *subview in [self arrangedSubviews]) {
        if ([subview isHidden]) {
            continue;
        }

        // Align to siblings
        if (previousSubview == nil) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTop
                relatedBy:NSLayoutRelationEqual toItem:self attribute:topAttribute
                multiplier:1 constant:_topSpacing]];
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
                relatedBy:NSLayoutRelationEqual toItem:self attribute:leftAttribute
                multiplier:1 constant:0]];
        } else if (alignment == LMBoxViewAlignmentRight) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeRight
                relatedBy:NSLayoutRelationEqual toItem:self attribute:rightAttribute
                multiplier:1 constant:0]];
        } else if (alignment == LMBoxViewAlignmentLeading) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeading
                relatedBy:NSLayoutRelationEqual toItem:self attribute:leadingAttribute
                multiplier:1 constant:0]];
        } else if (alignment == LMBoxViewAlignmentTrailing) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeTrailing
                relatedBy:NSLayoutRelationEqual toItem:self attribute:trailingAttribute
                multiplier:1 constant:0]];
        } else if (alignment == LMBoxViewAlignmentCenter) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeCenterX
                relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX
                multiplier:1 constant:0]];
        } else if (alignment == LMBoxViewAlignmentFill) {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeLeft
                relatedBy:NSLayoutRelationEqual toItem:self attribute:leftAttribute
                multiplier:1 constant:0]];
            [constraints addObject:[NSLayoutConstraint constraintWithItem:subview attribute:NSLayoutAttributeRight
                relatedBy:NSLayoutRelationEqual toItem:self attribute:rightAttribute
                multiplier:1 constant:0]];
        } else {
            [NSException raise:NSInternalInconsistencyException format:@"Unexpected horizontal alignment."];
        }

        // Align subviews
        if ([self alignToGrid] && [subview isKindOfClass:[LMRowView self]] && [previousSubview isKindOfClass:[LMRowView self]]) {
            NSArray *nestedSubviews = [(LMRowView *)subview arrangedSubviews];
            NSArray *previousNestedSubviews = [(LMRowView *)previousSubview arrangedSubviews];

            for (NSUInteger i = 0, n = MIN([nestedSubviews count], [previousNestedSubviews count]); i < n; i++) {
                UIView *nestedSubview = [nestedSubviews objectAtIndex:i];
                UIView *previousNestedSubview = [previousNestedSubviews objectAtIndex:i];

                [constraints addObject:[NSLayoutConstraint constraintWithItem:nestedSubview attribute:NSLayoutAttributeWidth
                    relatedBy:NSLayoutRelationEqual toItem:previousNestedSubview attribute:NSLayoutAttributeWidth
                    multiplier:1 constant:0]];
            }
        }

        previousSubview = subview;
    }

    // Align final view to bottom edge
    if (previousSubview != nil) {
        [constraints addObject:[NSLayoutConstraint constraintWithItem:previousSubview attribute:NSLayoutAttributeBottom
            relatedBy:NSLayoutRelationEqual toItem:self attribute:bottomAttribute
            multiplier:1 constant:_bottomSpacing]];
    }

    return constraints;
}

@end
