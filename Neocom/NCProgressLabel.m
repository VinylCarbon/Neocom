//
//  NCProgressLabel.m
//  Neocom
//
//  Created by Артем Шиманский on 28.01.14.
//  Copyright (c) 2014 Artem Shimanski. All rights reserved.
//

#import "NCProgressLabel.h"

@implementation NCProgressLabel

- (void) awakeFromNib {
//	[super setBackgroundColor:[UIColor clearColor]];
	self.progress = 0;
}

/*- (void) setBackgroundColor:(UIColor *)backgroundColor {
	self.color = backgroundColor;
}*/

- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void) setHighlighted:(BOOL)highlighted {
	
}

- (void)drawRect:(CGRect)rect {
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	const float *components = CGColorGetComponents([self.backgroundColor CGColor]);
	CGContextSetRGBFillColor(context, components[0] * 0.4, components[1] * 0.4, components[2] * 0.4, 1);
	CGContextFillRect(context, rect);
	
	float scale;
	if (self.progress > 1.0) {
		CGContextSetFillColorWithColor(context, [[UIColor redColor] CGColor]);
		scale = 1;
	}
	else {
		CGContextSetFillColorWithColor(context, [self.backgroundColor CGColor]);
		scale = self.progress;
	}
	CGContextFillRect(context, CGRectMake(rect.origin.x, rect.origin.y, rect.size.width * scale, rect.size.height));
	
	CGContextSetRGBStrokeColor(context, 0, 0, 0, 1);
	CGContextStrokeRectWithWidth(context, rect, 1);
	[self.text drawInRect:rect withFont:self.font lineBreakMode:self.lineBreakMode alignment:self.textAlignment];
	//[super drawRect:rect];
}

- (void) setProgress:(float)value {
	_progress = value;
	[self setNeedsDisplay];
}

@end
