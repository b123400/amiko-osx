/*
 
 Copyright (c) 2017 Max Lungarella <cybrmx@gmail.com>
 
 Created on 27/04/2017.
 
 This file is part of AmiKo for OSX.
 
 AmiKo for OSX is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 
 ------------------------------------------------------------------------ */

#import "MLFullTextEntry.h"

@interface MLFullTextDBAdapter : NSObject

- (BOOL) openDatabase: (NSString *)dbName;
- (void) closeDatabase;
- (NSInteger) getNumRecords;
- (MLFullTextEntry *) searchHash:(NSString *)hash;
- (NSArray *) searchKeyword: (NSString *)keyword;
- (MLFullTextEntry *) cursorToFullTextEntry:(NSArray *)cursor;
- (NSArray *) extractFullTextEntryFrom:(NSArray *)results;

@end
