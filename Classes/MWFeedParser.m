//
//  TBFeedParser.m
//  NOAA KMLViewer
//
//  Created by Tibi on 4/10/15.
//
//

#import "TBFeedParserNWS.h"

@implementation TBFeedParserNWS
@synthesize landAlerts, marineAlerts, landShapeLookup, marineShapesLookup;

- (id) init {
    self = [super init];
    if (self) {
        [self initDatabases];
    }
    return self;
}

- (void) initDatabases {

    
    /*NSLog(@"Land Starts");
    NSURL *landZonesJsonURL   = [[NSBundle mainBundle] URLForResource:@"County-Zones" withExtension:@"json"];
    NSDictionary *landGeoJSON = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:landZonesJsonURL] options:0 error:nil];
    NSArray *landFeatures     = landGeoJSON[@"features"];
    landShapeLookup = [NSMutableDictionary dictionary];
    for (int i = 0; i<landFeatures.count; i++) {
        id landFeatureGeometry = [GeoJSONSerialization shapeFromGeoJSONFeature:landFeatures[i] error:nil];
        if ([landFeatureGeometry isKindOfClass:[NSArray class]]) {
            NSLog(@"NSArray");
            [landShapeLookup setObject:landFeatureGeometry forKey:landFeatures[i] [@"properties"][@"GEOID"]];

        } else if ([landFeatureGeometry isKindOfClass:[MKShape class]]) {
            NSLog(@"MKSape");
            [landShapeLookup setObject:[NSArray arrayWithObject:landFeatureGeometry] forKey:landFeatures[i] [@"properties"][@"GEOID"]];
        }
    }
    NSLog(@"Land Finishes");*/

    
    NSLog(@"Land Starts");
    NSURL *landZonesJsonURL   = [[NSBundle mainBundle] URLForResource:@"Land-Zones-5" withExtension:@"json"];
    NSDictionary *landGeoJSON = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:landZonesJsonURL] options:0 error:nil];
    NSArray *landFeatures     = landGeoJSON[@"features"];
    landShapeLookup = [NSMutableDictionary dictionary];
    for (int i = 0; i<landFeatures.count; i++) {
        NSDictionary *landFeatureProperties = landFeatures[i][@"properties"];
        id landFeatureGeometry = [GeoJSONSerialization shapeFromGeoJSONFeature:landFeatures[i] error:nil];
        if ([landFeatureGeometry isKindOfClass:[NSArray class]]) {
            [landShapeLookup setObject:landFeatureGeometry forKey:landFeatureProperties[@"STATE_ZONE"]];
        } else if ([landFeatureGeometry isKindOfClass:[MKShape class]]) {
            [landShapeLookup setObject:[NSArray arrayWithObject:landFeatureGeometry] forKey:landFeatureProperties[@"STATE_ZONE"]];
        } else {
            NSLog(@"Error");
        }
    }
    NSLog(@"Land Finishes");
    
    NSLog(@"Marine Starts");
    NSURL *marineZonesJsonURL   = [[NSBundle mainBundle] URLForResource:@"Marine-Zones" withExtension:@"json"];
    NSDictionary *marineGeoJSON = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:marineZonesJsonURL] options:0 error:nil];
    NSArray *marineFeatures     = marineGeoJSON[@"features"];
    marineShapesLookup = [NSMutableDictionary dictionary];
    for (int i = 0; i<marineFeatures.count; i++) {
        id marineFeatureGeometry = [GeoJSONSerialization shapeFromGeoJSONFeature:marineFeatures[i] error:nil];
        if ([marineFeatureGeometry isKindOfClass:[NSArray class]]) {
            [marineShapesLookup setObject:marineFeatureGeometry forKey:marineFeatures[i] [@"properties"][@"ID"]];
            
        } else if ([marineFeatureGeometry isKindOfClass:[MKShape class]]) {
            [marineShapesLookup setObject:[NSArray arrayWithObject:marineFeatureGeometry] forKey:marineFeatures[i] [@"properties"][@"ID"]];
        }
    }
    NSLog(@"Marine Finishes");
   
}

- (void) startFeedParseLand {
    
    NSString *documentDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
NSString *filePath = [documentDir stringByAppendingPathComponent:@"alert.xml"];

NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://alerts.weather.gov/cap/us.php?x=0"]];
[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue currentQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
    if (error) {
        NSLog(@"Download Error:%@",error.description);
    }
    if (data) {
        [data writeToFile:filePath atomically:YES];
        NSLog(@"File is saved to %@",filePath);
    }
}];

    
    //land parsing
    landTempParsedItems = [NSMutableArray array];

    landFeedParser = [[MWFeedParser alloc] initWithFeedURL:[NSURL URLWithString:@"https://alerts.weather.gov/cap/us.php?x=0"]];
    landFeedParser.delegate = self;
    landFeedParser.feedParseType = ParseTypeFull; // Parse feed info and all items
    landFeedParser.connectionType = ConnectionTypeAsynchronously;
    landFeedParser.customKeys = @[@"cap:event",@"cap:effective",@"cap:expires",@"cap:status",@"cap:msgType",@"cap:category",@"cap:urgency",@"cap:severity",@"cap:certainty",@"cap:areaDesc",@"cap:polygon",@"cap:geocode/value",@"cap:parameter/value"];
    [landFeedParser parse];
}

- (void) startFeedParseMarine {
    //marine parsing
    marineTempParsedItems = [NSMutableArray array];
    
    marineFeedParser = [[MWFeedParser alloc] initWithFeedURL:[NSURL URLWithString:@"http://alerts.weather.gov/cap/mzus.php?x=1"]];
    marineFeedParser.delegate = self;
    marineFeedParser.feedParseType = ParseTypeFull; // Parse feed info and all items
    marineFeedParser.connectionType = ConnectionTypeAsynchronously;
    marineFeedParser.customKeys = @[@"cap:event",@"cap:effective",@"cap:expires",@"cap:status",@"cap:msgType",@"cap:category",@"cap:urgency",@"cap:severity",@"cap:certainty",@"cap:areaDesc",@"cap:polygon",@"cap:geocode/value",@"cap:parameter/value"];
    [marineFeedParser parse];
}



- (void)refresh {
    //[tempParsedItems removeAllObjects];
    //[feedParser stopParsing];
    //[feedParser parse];
}

#pragma mark MWFeedParserDelegate

- (void)feedParserDidStart:(MWFeedParser *)parser {
    NSLog(@"Started Parsing: %@", parser.url);
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info {
    NSLog(@"Parsed Feed Info: “%@”", info.title);
    //self.title = info.title;
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item {
    //NSLog(@"Parsed Feed Item: “%@”", item.title);
    if (item) {
        if (parser == landFeedParser) {
            [landTempParsedItems addObject:item];
        } else {
            [marineTempParsedItems addObject:item];
        }
    }
}

- (void)feedParserDidFinish:(MWFeedParser *)parser {
    NSLog(@"Finished Parsing%@", (parser.stopped ? @" (Stopped)" : @""));
    //[self updateTableWithParsedItems];
    
    //feedParser.customKeys = @[@"cap:event",@"cap:effective",@"cap:expires",@"cap:status",@"cap:msgType",@"cap:category",@"cap:urgency",@"cap:severity",@"cap:certainty",@"cap:areaDesc",@"cap:polygon",@"cap:geocode/value",@"cap:parameter/value:VTEC"];
    NSMutableArray *alerts = [NSMutableArray array];
    
    NSArray *tempParsedItems = (parser == landFeedParser)?landTempParsedItems:marineTempParsedItems;
    
    for (MWFeedItem *item in tempParsedItems) {
        NSMutableDictionary *alert = [NSMutableDictionary dictionary];
        
        //Special Weather Statement
        NSString *title      = item.customProperties[@"cap:event"];
        [self dictonary:alert trySetObject:title forKey:@"title"];
        
        //Special Weather Statement issued April 10 at 8:53AM CDT by NWS
        NSString *subTitle     = item.title;
        [self dictonary:alert trySetObject:subTitle forKey:@"subTitle"];

        //http://alerts.weather.gov/cap/wwacapget.php?x=AL1253A209C704.SpecialWeatherStatement.1253A209E518AL.BMXSPSBMX.2d939d384458c1283c65a0948a624db0
        NSString *identifier = item.identifier;
        [self dictonary:alert trySetObject:identifier forKey:@"identifier"];

        //Alert
        NSString *type      = item.customProperties[@"cap:msgType"];
        [self dictonary:alert trySetObject:type forKey:@"type"];

        //Actual
        NSString *status      = item.customProperties[@"cap:status"];
        [self dictonary:alert trySetObject:status forKey:@"status"];

        //Expected
        NSString *urgency      = item.customProperties[@"cap:urgency"];
        [self dictonary:alert trySetObject:urgency forKey:@"urgency"];

        //Minor
        NSString *severity      = item.customProperties[@"cap:severity"];
        [self dictonary:alert trySetObject:severity forKey:@"severity"];

        //Likely
        NSString *certainty      = item.customProperties[@"cap:certainty"];
        [self dictonary:alert trySetObject:certainty forKey:@"certainty"];

        
        //dates
        NSDate   *updated    = item.updated;
        [self dictonary:alert trySetObject:updated forKey:@"updated"];
        
        NSDate   *published  = item.date;
        [self dictonary:alert trySetObject:published forKey:@"published"];
        
        NSDate   *effective  = [NSDate dateFromInternetDateTimeString:item.customProperties[@"cap:effective"] formatHint:DateFormatHintRFC3339];
        [self dictonary:alert trySetObject:effective forKey:@"effective"];

        NSDate   *expires    = [NSDate dateFromInternetDateTimeString:item.customProperties[@"cap:expires"] formatHint:DateFormatHintRFC3339];
        [self dictonary:alert trySetObject:expires forKey:@"expires"];
        
        
        //link=identifier
        NSString *link       = item.link;
        [self dictonary:alert trySetObject:link forKey:@"link"];

        //...SIGNIFICANT WEATHER ADVISORY FOR CLAY COUNTY UNTIL 930 AM CDT... AT 852 AM CDT...DOPPLER RADAR WAS TRACKING A STRONG THUNDERSTORM 7 MILES WEST OF ASHLAND...MOVING EAST AT 35 MPH. WINDS IN EXCESS OF 40 MPH WILL BE POSSIBLE WITH THIS STORM. LOCATIONS IMPACTED INCLUDE... LINEVILLE...ASHLAND...BARFIELD...DELTA...ROSELLE...GUNTHERTOWN...
        NSString *summary    = item.summary;
        [self dictonary:alert trySetObject:summary forKey:@"summary"];
        
        //Independence; Jackson; Lawrence
        NSString *areas      = item.customProperties[@"cap:areaDesc"];
        [self dictonary:alert trySetObject:areas forKey:@"areas"];
        
        //35.7,-91.4 35.91,-91.25 36.12,-91.15 36.1,-91.01 35.88,-91.1 35.64,-91.28 35.7,-91.4
        NSArray  *polygon    = [((NSString *)item.customProperties[@"cap:polygon"]) componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@", "]];
        [self dictonary:alert trySetObject:polygon forKey:@"polygon"];
        
        //005063 005067 005075
        NSArray  *zonesFIPS6  = [((NSString *)item.customProperties[@"cap:geocode/value"]) componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        [self dictonary:alert trySetObject:zonesFIPS6 forKey:@"zones"];
        
        //ARC063 ARC067 ARC075
        NSArray  *zonesUGC  = [((NSString *)item.customProperties[@"cap:geocode/value+"]) componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        [self dictonary:alert trySetObject:zonesUGC forKey:@"zonesUGC"];
        
        // /O.CON.KLZK.FL.W.0010.000000T0000Z-000000T0000Z/
        // /BKRA4.1.ER.150305T1022Z.150315T0700Z.000000T0000Z.NO/
        NSString *VTEC        = item.customProperties[@"cap:parameter/value"];
        [self dictonary:alert trySetObject:VTEC forKey:@"VTEC"];
        [alerts addObject:alert];
        
        //NSLog(@"%@ - %@ - %@ - %@- %@ - %@ - %@" ,title,type,status,urgency,severity,certainty,(polygon?@"Polygon: YES":@"Polygon: NO"));
    }
    
    if (parser == landFeedParser) {
        landAlerts = alerts;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NWSAlertsUpated" object:self userInfo:nil];
        NSLog(@"Finished Alerts");
    } else {
        marineAlerts = alerts;
        NSLog(@"Finished Marine Alerts");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NWSMarineAlertsUpated" object:self userInfo:nil];
    }
    if (landAlerts && marineAlerts) {
        NSLog(@"Both alerst are phrased");
        [[NSNotificationCenter defaultCenter] postNotificationName:@"NWSAlertsUpated" object:self userInfo:@{@"FeedParserNWS":self}];
    }

}

//prevent nil objects to be added
- (void) dictonary:(NSMutableDictionary *) dict trySetObject: (id) object forKey:(NSString *) key {
    if (object) {
        [dict setObject:object forKey:key];
    }
}

- (void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error {
    NSLog(@"Finished Parsing With Error: %@", error);
}



@end
