# SpineVideoObjCDemo


## Setup
in root directory and spine-cocos2d-objc, run:

  cmake CMakeLists.txt
  
## Compile errors fix
### cocos2d for iphone
#### error: Expected method to read dictionary element not found on object of type 'id<NSCopying>'
in CCRendererBasicTypes.m, replace the following line
  
  -(id)objectForKey:(id<NSCopying>)options

With new code:

  -(id)objectForKey:(id)options

### cocos2d-x
#### error:  Argument value 10880 is outside the valid range [0, 255]   in  btVector3.h
Temporary solution suggested in this forum : https://discuss.cocos2d-x.org/t/xcode-11-ios-13-cocos-not-running/46825

In btVector3.h, just replace

#define BT_SHUFFLE(x,y,z,w) ((w)<<6 | (z)<<4 | (y)<<2 | (x))

With new code:

#define BT_SHUFFLE(x, y, z, w) (((w) << 6 | (z) << 4 | (y) << 2 | (x)) & 0xff)
