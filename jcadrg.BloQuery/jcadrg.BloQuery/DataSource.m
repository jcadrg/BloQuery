//
//  DataSource.m
//  jcadrg.BloQuery
//
//  Created by Mac on 8/24/15.
//  Copyright (c) 2015 Mac. All rights reserved.
//
#import <Parse/Parse.h> //Did not import parse

#import "DataSource.h"
#import "User.h"
#import "Query.h"
#import "NewAnswer.h"


@implementation DataSource

+(instancetype) sharedInstance{
    
    static dispatch_once_t once;
    static id sharedInstance;
    
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

-(instancetype) init{
    self = [super init];
    
    if (self) {
        
    }
    
    
    
    return self;
}


/*-(void) retrieveQueryFromParse{
    
    NSMutableArray *queryArray = [NSMutableArray array];
    
    PFQuery *query =[PFQuery queryWithClassName:@"Query"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error){
            
            NSLog(@"Retrieved %lu queries", (unsigned long)objects.count);
            
            for (PFObject *object in objects){
                
                [queryArray addObject:object];
                
            }
        }else{
            NSLog(@"Error retrieving queries : %@", error);
        }
        
        [DataSource sharedInstance].queryElements =queryArray;
    }];
    
    
    
}*/

#pragma mark - query methods
 
-(void) retrieveQueryWithCompletionHandler:(requestedQueryCompletionBlock) completionhandler{
    
    
    NSMutableArray *queryArray = [NSMutableArray array];
    
    PFQuery *query =[PFQuery queryWithClassName:@"Query"];
    
    [query includeKey:@"user"];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error){
            
            NSLog(@"Retrieved %lu queries", (unsigned long)objects.count);
            
            for (PFObject *object in objects){
                
                [queryArray insertObject:object atIndex:0];
                
            }
            
            [DataSource sharedInstance].queryElements = queryArray;
            
            if (completionhandler) {
                completionhandler(nil);
            }
            
        
        }else{
            NSLog(@"Error retrieving queries : %@", error);
        }
        
        /*[DataSource sharedInstance].queryElements =queryArray;
        
        if (completionhandler) {
            completionhandler(nil);
        }*/
    }];
    
}

-(void) submitQuery:(NSString *)queryText withCompletionHandler:(submittedAnswerCompletionBlock)completionHandler{
    
    if ([User currentUser]) {
        Query *newQuestion = [Query object];
        newQuestion.user = [User currentUser];
        newQuestion.query = queryText;
        
        NSArray *answersList = @[];
        [newQuestion setObject:answersList forKey:@"answersList"];
        //newQuestion.answerList = answersList;
        
        [newQuestion saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            if(succeeded){
                if (completionHandler) {
                    completionHandler(nil);
                }
                
            }else{
                NSLog(@"Queery creation failed");
            }
            
            
        }];
        
    }
}

#pragma mark - answer methods

-(void) submitAnswersForQueries:(Query *)query withText:(NSString *)queryText withCompletionHandler:(submittedQueryCompletionBlock)completionHandler{
    
    if ([User currentUser]) {
        NSLog(@"Got to submit method!");
        NewAnswer *newAnswer = [NewAnswer object];
        newAnswer.username = [User currentUser];
        /*newAnswer.userupVoteList = @[];
        newAnswer.state = NO;*/
        
        newAnswer.upVoteCounter = 0;

        newAnswer.textAnswer =  queryText;
        //newAnswer.query = query;
        
        [newAnswer setObject:query forKey:@"query"];
        
        NSLog(@"answer object : %@", newAnswer);
        
        /*NSMutableArray *answerListCopy = [query.answersList mutableCopy];
        [answerListCopy addObject:newAnswer];
        [query setObject:[answerListCopy copy] forKey:@"answersList"];*/
        
        [query.answersList addObject:newAnswer];
        //query.answerCount += 1;
  
        
        [query saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            NSLog(@"Request to save query with answer fired");
            if(succeeded){
                
                if (completionHandler) {
                    completionHandler(nil);
                }
                
                NSLog(@"Answer creation succeeded");

            }else{
                NSLog(@"Answer creation failed");
            }
        
            
        }];
        
    }
    
}

-(void) retrieveAnswersForQueries:(Query *)query withCompletionHandler:(requestedAnswerCompletionBlock)completionHandler{
    
    NSMutableArray *answersArray = [NSMutableArray array];
    
    PFQuery *answer =[PFQuery queryWithClassName:@"NewAnswer"];
    
    [answer whereKey:@"query" equalTo:query];
    [answer findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        if (!error){
            
            NSLog(@"Retrieved %lu answers", (unsigned long)objects.count);
            
            for (PFObject *object in objects){
                
                [answersArray addObject:object];
                
            }
            
            query.answersList = answersArray;

            
            if (completionHandler) {
                completionHandler(nil);
            }
            
            
        }else{
            NSLog(@"Error retrieving queries : %@", error);
        }
        
    }];
    
}




#pragma mark - Config method

//Method copied from the Parse iOS tutorial

-(void) retrieveParseConfig{
    
    NSLog(@"Getting the latest config...");
    [PFConfig getConfigInBackgroundWithBlock:^(PFConfig *config, NSError *error) {
        if (!error) {
            NSLog(@"Yay! Config was fetched from the server.");
        } else {
            NSLog(@"Failed to fetch. Using Cached Config.");
            config = [PFConfig currentConfig];
        }
        
        self.configNewQuestion = config[@"New Question"];
        if (!self.configNewQuestion) {
            self.configNewQuestion = @"Ask your question!";
        }
        
        self.configNewQuestion = config[@"New Answer"];
        if (!self.configNewQuestion) {
            self.configNewQuestion = @"Answer the question!";
        }


    }];
}

#pragma mark - Image request

/*-(void) retrieveUserProfile:(User *)user withCompletionHandler:(retrieveUserProfileImageCompletionBlock)completionHandler{
    
}*/

-(void) updateupVoteCounter:(NewAnswer *)answer withCompletionHandler:(upVoteCounterChangeCompletionBlock)completionHandler{
    
    if ([User currentUser]) {
        NSMutableArray *upVoteUserArray = [answer.userupVoteList mutableCopy];
        [upVoteUserArray addObject:[User currentUser]];
        answer.userupVoteList = upVoteUserArray;
        answer.upVoteCounter +=1;
        [answer saveInBackgroundWithBlock:^(BOOL succeded, NSError *error){
            if (succeded) {
                if (completionHandler) {
                    completionHandler(nil);
                    
                }else{
                    NSLog(@"Could not update upVote count!");
                }
            }
        }];
    }
}

@end


