//
//  BrowserViewController.h
//  Radio Switch
//
//  Created by Olga Dalton on 25/07/2012.
//  Copyright (c) 2012 Olga Dalton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FixedTextField.h"


enum PickerType {
    GenrePicker = 0,
    CountryPicker = 1
};

@interface BrowserViewController : UIViewController <UIWebViewDelegate, UIAlertViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource>
{
    IBOutlet UIButton *backButton, *nextButton;
    IBOutlet UITextField *addressBar;
    IBOutlet UIButton *goButton;
    IBOutlet UIWebView *webView;
    
    UIAlertView *alertWithSpinner;
    
    id lastResponder;
    
    IBOutlet UIActivityIndicatorView *waitSpinner;
    
    NSString *lastResult;
    
    UITextField *alertTextField;
    
    BOOL disappeared;
    
    BOOL inEditing;
    
    IBOutlet UIView *pickerMainView;
    IBOutlet UINavigationBar *pickerNavbar;
    IBOutlet UINavigationItem *pickerNavItem;
    
    BOOL pickerVisible;
    
    IBOutlet FixedTextField *stationNameField;
    IBOutlet FixedTextField *stationURLField;
    IBOutlet UIButton *genreButton, *countryButton;
    IBOutlet UIPickerView *selectionPicker;
    
    enum PickerType currentPickerType;
    
    IBOutlet UIButton *cancelButton, *selectButton;
    
    int selectedRow;
    
    NSString *lastSelectedCode, *lastSelectedGenre;
    
    BOOL onButton;
    
    FixedTextField *currentTextField;
    
    BOOL editingInProcess;
}

@property (nonatomic, retain) FixedTextField *currentTextField;

@property (nonatomic, retain) IBOutlet UIButton *backButton, *nextButton;
@property (nonatomic, retain) IBOutlet UITextField *addressBar;
@property (nonatomic, retain) IBOutlet UIButton *goButton;
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) UIAlertView *alertWithSpinner;
@property (nonatomic, retain) id lastResponder;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *waitSpinner;
@property (nonatomic, retain) NSString *lastResult;
@property (nonatomic, retain) UITextField *alertTextField;

@property (nonatomic, retain) IBOutlet UIView *pickerMainView;
@property (nonatomic, retain) IBOutlet UINavigationBar *pickerNavbar;
@property (nonatomic, retain) IBOutlet UINavigationItem *pickerNavItem;

@property (nonatomic, retain) IBOutlet FixedTextField *stationNameField;
@property (nonatomic, retain) IBOutlet FixedTextField *stationURLField;

@property (nonatomic, retain) IBOutlet UIButton *genreButton, *countryButton;

@property (nonatomic, retain) IBOutlet UIPickerView *selectionPicker;
@property (nonatomic, retain) IBOutlet UIButton *cancelButton, *selectButton;
@property (nonatomic, retain) NSString *lastSelectedCode, *lastSelectedGenre;

-(IBAction)textFieldEditingFinished:(id)sender;

-(IBAction) goToUrl: (id) sender;
-(void)dismissPicker;
-(void) controlButtons;

-(void)disableWebViewBouncing:(UIWebView *)webview andScrolling:(BOOL)disableScrolling;

-(void) analyzerFinishedForUrl: (NSString *) url withResult: (NSString *) result;
-(void) analyzerFailedForUrl: (NSString *) url;

-(void) analyze;

@end
