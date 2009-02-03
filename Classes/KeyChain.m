/* 
 * Shift is the legal property of its developers, whose names are listed in the copyright file included
 * with this source distribution.
 * 
 * This program is free software; you can redistribute it and/or modify it under the terms of the GNU
 * General Public License as published by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
 * the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
 * Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License along with this program; if not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA 
 * or see <http://www.gnu.org/licenses/>.
 */

#import "KeyChain.h"
#import <Security/Security.h>


@implementation KeyChain

- (NSString *)getAccountNameForFavorite:(NSString *)name ofType:(NSString *)type
{
	return [[NSArray arrayWithObjects:type,@" - ",name,nil] componentsJoinedByString:@""];
}

- (NSString *)getServiceNameForAccount:(NSString *)account
{
	return [@"Shift : " stringByAppendingString:account];
}

- (NSString *)getPasswordForFavorite:(NSString *)name ofType:(NSString *)type
{
    OSStatus code;
    UInt32 passwordLength;
    char *passwordData;

	NSString *account = [self getAccountNameForFavorite:name ofType:type];
	NSString *serviceName = [self getServiceNameForAccount:account];

	code = SecKeychainFindGenericPassword(NULL, [serviceName length], [serviceName UTF8String], [account length], [account UTF8String], &passwordLength, (void**)&passwordData, NULL);
	
    if (code == noErr){
		return [[[NSString alloc] initWithCStringNoCopy:passwordData length:passwordLength freeWhenDone:YES] autorelease];
	}else
		return @"";
}

- (void)setPasswordForFavorite:(NSString *)name ofType:(NSString *)type to:(NSString *)password
{
    OSStatus code;
    UInt32 passwordLength;
    char *passwordData;
	SecKeychainItemRef item;
	
	NSString *account = [self getAccountNameForFavorite:name ofType:type];
	NSString *serviceName = [self getServiceNameForAccount:account];
	
	code = SecKeychainFindGenericPassword(NULL, [serviceName length], [serviceName UTF8String], [account length], [account UTF8String], &passwordLength, (void**)&passwordData, &item);
	if (code == noErr){
		code = SecKeychainItemModifyContent(item, NULL, [password length], [password UTF8String]);
		SecKeychainItemFreeContent(NULL, passwordData);
		CFRelease(item);
	}else if (code == errSecItemNotFound)
		SecKeychainAddGenericPassword(NULL, [serviceName length], [serviceName UTF8String], [account length], [account UTF8String], [password length], [password UTF8String], NULL);
}


- (void)deletePasswordForFavorite:(NSString *)name ofType:(NSString *)type
{
	OSStatus code;
	UInt32 passwordLength;
	char* passwordData;
	SecKeychainItemRef item;
	
	NSString *account = [self getAccountNameForFavorite:name ofType:type];
	NSString *serviceName = [self getServiceNameForAccount:account];
	
	code = SecKeychainFindGenericPassword(NULL, [serviceName length], [serviceName UTF8String], [account length], [account UTF8String], &passwordLength, (void**)&passwordData, &item);
	
	if (code == noErr && item) {
		//delete it
		code = SecKeychainItemDelete(item);
		//clean up
		SecKeychainItemFreeContent(NULL, passwordData);
		CFRelease(item);
	}
}

@end
