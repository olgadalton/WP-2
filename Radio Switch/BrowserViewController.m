//
//  BrowserViewController.m
//  Radio Switch
//
//  Created by Olga Dalton on 25/07/2012.
//  Copyright (c) 2012 Olga Dalton. All rights reserved.
//

#import "BrowserViewController.h"
#import "PreferencesManager.h"
#import <QuartzCore/QuartzCore.h>
#import "SmartAnalyzer.h"
#import "RequestsManager.h"

@implementation BrowserViewController

@synthesize webView, backButton, nextButton, addressBar, goButton;
@synthesize alertWithSpinner, lastResponder, waitSpinner, lastResult;

@synthesize genreButton, countryButton, selectionPicker;
@synthesize cancelButton, selectButton, lastSelectedCode, lastSelectedGenre;

@synthesize pickerNavbar, pickerNavItem, pickerMainView;
@synthesize stationNameField, stationURLField, currentTextField;

@synthesize alertTextField;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void) showBottomPopup
{
    [self.selectButton setHidden: YES];
    [self.cancelButton setHidden: YES];
    [self.stationNameField setHidden: NO];
    [self.stationURLField setHidden: NO];
    
    [self.stationURLField setText: self.lastResult];
    
    [self.pickerNavbar setTintColor: [UIColor blackColor]];
    [self.pickerNavItem setTitle: NSLocalizedString(@"Add new station", nil)];
    
    [self.genreButton setTitle:NSLocalizedString(@"Genre", nil) forState:UIControlStateNormal];
    [self.countryButton setTitle:NSLocalizedString(@"Country", nil) forState:UIControlStateNormal];
    
    self.pickerNavItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(dismissPicker)] autorelease];
    
    self.pickerNavItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add", nil) style:UIBarButtonItemStyleDone target:self action:@selector(saveAndDismiss)] autorelease];
    
    pickerVisible = YES;
    
    [self.pickerMainView removeFromSuperview];
    
    CGRect datePickerFrame = self.pickerMainView.frame;
    
    datePickerFrame.size.height = 210.0f;
    
    [self.pickerMainView setFrame: CGRectMake(0.0, self.view.frame.size.height, datePickerFrame.size.width, datePickerFrame.size.height)];
    
    [self.view addSubview: self.pickerMainView];
    
    [UIView beginAnimations:@"" context: NULL];
    [UIView setAnimationDuration: 0.3f];
    [UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
    
    [self.pickerMainView setFrame: CGRectMake(0.0, self.view.frame.size.height - datePickerFrame.size.height, datePickerFrame.size.width, datePickerFrame.size.height)];
    
    [UIView commitAnimations];          
}

-(void) urlCheckDone: (NSNumber *) result
{
    BOOL isCorrect = [result boolValue];
    
    if (isCorrect  == YES)
    {
        [[PreferencesManager sharedManager] addStation: [NSDictionary dictionaryWithObjectsAndKeys:self.stationNameField.text, @"name", self.stationURLField.text, @"streamurl", self.lastSelectedCode, @"country", self.lastSelectedGenre, @"genre", nil]];
        
        [self dismissPicker];
    }
    else 
    {
        UIAlertView *errorAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"The url you entered is not correct!", nil) message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] autorelease];
        
        [errorAlert show];
    }
}

-(void) saveAndDismiss
{
    if (self.stationURLField.text.length && self.stationNameField.text.length 
        && self.countryButton.titleLabel.text.length && self.genreButton.titleLabel.text.length
        && ![self.genreButton.titleLabel.text isEqualToString:NSLocalizedString(@"Genre", nil)]
        && ![self.countryButton.titleLabel.text isEqualToString: NSLocalizedString(@"Country", nil)]) 
    {
        [self urlCheckDone: [NSNumber numberWithBool: YES]];
    }
    else
    {
        UIAlertView *errorAlert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Please fill in all fields!", nil) message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil] autorelease];
        
        [errorAlert show];
    }
}
         
         

-(IBAction)dismissKeyboard:(id)sender
{
    
    if ([sender isFirstResponder]) 
    {
        [sender resignFirstResponder];
        
        editingInProcess = NO;
        
        if (!onButton) 
        {
            [self performSelector:@selector(scrollMeUp) withObject: nil afterDelay:0.0f];
        }
    }
}


-(void) scrollMeUp
{
    if (!editingInProcess && pickerVisible) 
    {
        CGRect datePickerFrame = self.pickerMainView.frame;
        datePickerFrame.size.height = 210.0f;
        [UIView beginAnimations:@"" context: NULL];
        [UIView setAnimationDuration: 0.15f];
        [UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
        
        [self.pickerMainView setFrame: CGRectMake(0.0, self.view.frame.size.height - datePickerFrame.size.height, datePickerFrame.size.width, datePickerFrame.size.height)];
        
        [UIView commitAnimations]; 
    }
}

-(IBAction)editingDidStart:(id)sender
{
    self.currentTextField = sender;
    
    self.lastResponder = sender;
    inEditing = YES;
    
    if (pickerVisible == NO) 
    {
        return;
    }
    
    CGRect datePickerFrame = self.pickerMainView.frame;
    datePickerFrame.size.height = 210.0f;
    
    if (!editingInProcess) 
    {
        [UIView beginAnimations:@"" context: NULL];
        [UIView setAnimationDuration: 0.3f];
        [UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
        
        [self.pickerMainView setFrame: CGRectMake(0.0, 0.0f, datePickerFrame.size.width, datePickerFrame.size.height)];
        
        [UIView commitAnimations];
        
        editingInProcess = YES;
    }
}

-(void)dismissPicker
{
    if (pickerVisible == NO) 
    {
        return;
    }
    
    CGRect datePickerFrame = self.pickerMainView.frame;
    datePickerFrame.size.height = 210.0f;
    [UIView beginAnimations:@"" context: NULL];
    [UIView setAnimationDuration: 0.3f];
    [UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
    
    [self.pickerMainView setFrame: CGRectMake(0.0, self.view.frame.size.height, datePickerFrame.size.width, datePickerFrame.size.height)];
    
    [UIView commitAnimations];
    
    pickerVisible = NO;
    
    if (self.currentTextField && [self.currentTextField isFirstResponder]) 
    {
        [self.currentTextField resignFirstResponder];
    }
}



- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(IBAction)showGenrePicker:(id)sender
{
    currentPickerType = GenrePicker;
    [self.selectionPicker reloadAllComponents];
    onButton = YES;
    
    if (self.currentTextField && [self.currentTextField isFirstResponder])
    {
        [self.currentTextField resignFirstResponder];
        [self performSelector:@selector(setupPickerViewWithAnimation:) withObject:[NSNumber numberWithBool:NO] afterDelay:0.0f];
    }
    else
    {
        [self performSelector:@selector(setupPickerViewWithAnimation:) withObject:[NSNumber numberWithBool:YES] afterDelay:0.0f];
    }
}

-(IBAction)showCountryPicker:(id)sender
{
    currentPickerType = CountryPicker;
    [self.selectionPicker reloadAllComponents];
    onButton = YES;
    
    if (self.currentTextField && [self.currentTextField isFirstResponder])
    {
        [self.currentTextField resignFirstResponder];
        [self performSelector:@selector(setupPickerViewWithAnimation:) withObject:[NSNumber numberWithBool: NO] afterDelay:0.0f];
    }
    else
    {
        [self performSelector:@selector(setupPickerViewWithAnimation:) withObject:[NSNumber numberWithBool: NO] afterDelay:0.0f];
    }
}

-(void) setupPickerViewWithAnimation: (NSNumber *) animated
{
    
    CGRect datePickerFrame = self.pickerMainView.frame;
    datePickerFrame.size.height = 210.0f;
    
    if ([animated boolValue]) 
    {
        [UIView beginAnimations:@"" context: NULL];
        [UIView setAnimationDuration: 0.3f];
        [UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
    }
    
    [self.pickerMainView setFrame: CGRectMake(0.0, 0.0f, datePickerFrame.size.width, 369.0f)];
    
    [self.stationNameField setHidden: YES];
    [self.stationURLField setHidden: YES];
    
    [self.selectButton setHidden: NO];
    [self.cancelButton setHidden: NO];
    
    CGRect genreBtnFrame = self.genreButton.frame;
    CGRect countryBtnFrame = self.countryButton.frame;
    
    genreBtnFrame.origin.y  = 54.0f;
    countryBtnFrame.origin.y = 54.0f;
    
    self.genreButton.frame = genreBtnFrame;
    self.countryButton.frame = countryBtnFrame;
    
    if ([animated boolValue]) 
    {
        [UIView commitAnimations];
    }
    
    if (currentPickerType == GenrePicker)
    {
        if (self.lastSelectedGenre)
        {
            for (NSDictionary *genre in [RequestsManager sharedManager].allData)
            {
                if ([[genre objectForKey: @"name"] isEqualToString: self.lastSelectedGenre])
                {
                    selectedRow = [[RequestsManager sharedManager].allData indexOfObject: genre];
                    [self.selectionPicker selectRow:selectedRow inComponent:0 animated:YES];
                    break;
                }
            }
        }
        else
        {
            [self.selectionPicker selectRow:0 inComponent:0 animated:YES];
        }
    }
    else
    {
        if (self.lastSelectedCode)
        {
            for (NSString *code in [NSLocale ISOCountryCodes])
            {
                if ([code isEqualToString: self.lastSelectedCode])
                {
                    selectedRow = [[NSLocale ISOCountryCodes] indexOfObject: code];
                    [self.selectionPicker selectRow:selectedRow inComponent:0 animated:YES];
                    break;
                }
            }
        }
        else
        {
            [self.selectionPicker selectRow:0 inComponent:0 animated:YES];
        }
    }
}

-(void) desetupPickerView
{
    onButton = NO;
    
    CGRect datePickerFrame = self.pickerMainView.frame;
    [UIView beginAnimations:@"" context: NULL];
    [UIView setAnimationDuration: 0.3f];
    [UIView setAnimationCurve: UIViewAnimationCurveEaseIn];
    
    datePickerFrame.size.height = 210.0f;
    
    [self.pickerMainView setFrame: CGRectMake(0.0, self.view.frame.size.height - datePickerFrame.size.height, datePickerFrame.size.width, 369.0f)];
    
    [self.stationNameField setHidden: NO];
    [self.stationURLField setHidden: NO];
    
    [self.selectButton setHidden: YES];
    [self.cancelButton setHidden: YES];
    
    CGRect genreBtnFrame = self.genreButton.frame;
    CGRect countryBtnFrame = self.countryButton.frame;
    
    genreBtnFrame.origin.y  = 160.0f;
    countryBtnFrame.origin.y = 160.0f;
    
    self.genreButton.frame = genreBtnFrame;
    self.countryButton.frame = countryBtnFrame;
    
    //    CGRect viewFrame = self.view.frame;
    //    viewFrame.size.height = 210.0f;
    //    self.view.frame = viewFrame;
    
    [UIView commitAnimations];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (currentPickerType == GenrePicker)
    {
        return [[RequestsManager sharedManager].allData count];
    }
    else if(currentPickerType == CountryPicker)
    {
        return [[NSLocale ISOCountryCodes] count];
    }
    
    return 0;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (currentPickerType == GenrePicker)
    {
        return [[[RequestsManager sharedManager].allData objectAtIndex: row] objectForKey: @"name"];
    }
    else if(currentPickerType == CountryPicker)
    {
        NSString *countryCode = [[NSLocale ISOCountryCodes] objectAtIndex: row];
        
        return [[NSLocale currentLocale]
                displayNameForKey:NSLocaleCountryCode
                value:countryCode];
    }
    return nil;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    selectedRow = row;
}

-(IBAction)selectPickerTitle:(id)sender
{
    if (currentPickerType == GenrePicker)
    {
        self.lastSelectedGenre = [self pickerView:self.selectionPicker titleForRow: selectedRow forComponent:0];
        [self.genreButton setTitle:self.lastSelectedGenre forState: UIControlStateNormal];
    }
    else
    {
        self.lastSelectedCode = [[NSLocale ISOCountryCodes] objectAtIndex: selectedRow];
        [self.countryButton setTitle:self.lastSelectedCode forState:UIControlStateNormal];
    }
    
    [self desetupPickerView];
}

-(IBAction)cancelPickerTitle:(id)sender
{
    [self desetupPickerView];
}

-(void) firstAnalyze
{
    [[SmartAnalyzer sharedAnalyzer].resultsToIgnore removeAllObjects];
    [self analyze];
}

-(void) analyze
{
    self.alertWithSpinner = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Checking URL...\nPlease wait!", nil) message:nil delegate:self cancelButtonTitle:nil otherButtonTitles: nil] autorelease];
    
    UIActivityIndicatorView *spinner = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
    
    [spinner setFrame: CGRectMake(124.0f, 73.0f, spinner.frame.size.width, spinner.frame.size.height)];
    
    [self.alertWithSpinner addSubview: spinner];
    [spinner startAnimating];
    
    [self.alertWithSpinner show];
    
    NSString *currentURL = [webView stringByEvaluatingJavaScriptFromString:@"window.location.href"];
    
    [[SmartAnalyzer sharedAnalyzer] analyzeUrl:currentURL withDelegate:self andErrorSelector:@selector(analyzerFailedForUrl:) andSuccessSelector: @selector(analyzerFinishedForUrl:withResult:)];
}

-(void) analyzerFinishedForUrl: (NSString *) url withResult: (NSString *) result
{
    [self.alertWithSpinner dismissWithClickedButtonIndex:-10 animated:YES];
    
    NSString *currentURL = [webView stringByEvaluatingJavaScriptFromString:@"window.location.href"];
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:
                           [NSString stringWithFormat:@"%@ %@",
                            NSLocalizedString(@"Stream URL found on ", nil), currentURL]  
                                                     message:[NSString stringWithFormat:@"Do you want to add %@ to stations list?", result] delegate:self 
                                           cancelButtonTitle:NSLocalizedString(@"No", nil) otherButtonTitles: NSLocalizedString(@"Yes", nil), NSLocalizedString(@"Continue searching", nil), nil] autorelease];
    
    self.lastResult = result;
    
    alert.tag = 155;
    
    [alert show];
    
    NSLog(@"analyzer finished for url - %@ and result - %@", url, result);
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 155 && buttonIndex == 2) 
    {
        [[SmartAnalyzer sharedAnalyzer].resultsToIgnore addObject: self.lastResult];
        
        [self analyze];
    }
    else if(alertView.tag == 155 && buttonIndex == 1)
    {
//        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 5.0f) 
//        {
//            UIAlertView *enterNameAlert = [[[UIAlertView alloc] initWithTitle:@"Please enter station name:" message:@" " delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Add", nil), nil] autorelease];
//            
//            [enterNameAlert setBackgroundColor:[UIColor whiteColor]];
//            
//            enterNameAlert.tag = 156;
//            
//            self.alertTextField = [[[UITextField alloc] initWithFrame:CGRectMake(20.0, 45.0, 245.0, 25.0)] autorelease];
//            
//            [enterNameAlert addSubview: self.alertTextField];
//            
//            [enterNameAlert show];
//        }
//        else
//        {
//            
//            UIAlertView *enterNameAlert = [[[UIAlertView alloc] initWithTitle:@"Please enter station name:" message: nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Add", nil), nil] autorelease];
//            
//            enterNameAlert.tag = 156;
//            
//            [enterNameAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
//            
//            [enterNameAlert show];
//        }
        
        [self showBottomPopup];
    }
    else if(alertView.tag == 156 && buttonIndex == 1)
    {
        BOOL textEntered = NO;
        
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 5.0f) 
        {
            textEntered = self.alertTextField.text.length > 0;
        }
        else
        {
            textEntered = [[[alertView textFieldAtIndex:0] text] length] > 0;
        }
        
        if (textEntered) 
        {
            if ([[[UIDevice currentDevice] systemVersion] floatValue] < 5.0f) 
            {
                [[PreferencesManager sharedManager] addStation: [NSDictionary dictionaryWithObjectsAndKeys:self.alertTextField.text, @"name", self.lastResult, @"streamurl", nil]];
            }
            else
            {
                [[PreferencesManager sharedManager] addStation: [NSDictionary dictionaryWithObjectsAndKeys:[[alertView textFieldAtIndex:0] text], @"name", self.lastResult, @"streamurl", nil]];
            }
            
            [self.navigationController popViewControllerAnimated:YES];
        }
        else
        {
            if ([[[UIDevice currentDevice] systemVersion] floatValue] < 5.0f) 
            {
                UIAlertView *enterNameAlert = [[[UIAlertView alloc] initWithTitle:@"Please enter CORRECT station name:" message:@" " delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Add", nil), nil] autorelease];
                
                [enterNameAlert setBackgroundColor:[UIColor whiteColor]];
                
                enterNameAlert.tag = 156;
                
                self.alertTextField = [[[UITextField alloc] initWithFrame:CGRectMake(20.0, 45.0, 245.0, 25.0)] autorelease];
                
                [enterNameAlert addSubview: self.alertTextField];
                
                [enterNameAlert show];
            }
            else
            {
                    
                UIAlertView *enterNameAlert = [[[UIAlertView alloc] initWithTitle:@"Please enter station name:" message: nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Add", nil), nil] autorelease];
                
                enterNameAlert.tag = 156;
                
                [enterNameAlert setAlertViewStyle:UIAlertViewStylePlainTextInput];
                
                [enterNameAlert show];
            }
        }
    }
}

-(void) analyzerFailedForUrl: (NSString *) url
{
    [self.alertWithSpinner dismissWithClickedButtonIndex:-10 animated:YES];
    
    NSString *currentURL = [webView stringByEvaluatingJavaScriptFromString:@"window.location.href"];
    
    UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:
                           [NSString stringWithFormat:@"%@ %@",
                            NSLocalizedString(@"No streams found on ", nil), currentURL]  
                            message:nil delegate:self 
                            cancelButtonTitle:@"OK" otherButtonTitles: nil] autorelease];
    
    [alert show];
    
    NSLog(@"analyzer failed for url - %@", url);
}

-(IBAction)textFieldEditingFinished:(id)sender
{
    if ([sender isFirstResponder]) 
    {
        [sender resignFirstResponder];
    }
    
    inEditing = NO;
    
    [self goToUrl: nil];
}

-(IBAction) goToUrl: (id) sender
{
    [[SmartAnalyzer sharedAnalyzer].resultsToIgnore removeAllObjects];
    
    if (self.lastResponder && [self.lastResponder isFirstResponder]) 
    {
        [self.lastResponder resignFirstResponder];
    }
    
    if ([self.addressBar.text length]) 
    {
        NSString *url = self.addressBar.text;
        
        if (![url hasPrefix: @"http"]) 
        {
            url = [NSString stringWithFormat:@"http://%@", url];
        }
        
        [self.webView loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: url]]];
        
        [[NSUserDefaults standardUserDefaults] setObject:url forKey:@"lastUrl"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

-(void) webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"webview did fail to load with an error - %@", [error description]);
}

-(void) webViewDidFinishLoad:(UIWebView *)webView
{
    [self controlButtons];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration: 0.2f];
    
    [self.goButton setHidden: NO];
    [self.waitSpinner setHidden: YES];
    
    if (!inEditing) 
    {
        self.addressBar.text = [self.webView stringByEvaluatingJavaScriptFromString:@"window.location.href"];
    }
    
    [UIView commitAnimations];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear: animated];
    [self performSelector: @selector(updateAddress) withObject:nil afterDelay:1.0f];
    disappeared = NO;
}

-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear: animated];
    disappeared = YES;
}

-(void) updateAddress
{
    self.addressBar.text = [self.webView stringByEvaluatingJavaScriptFromString:@"window.location.href"];
    
    if (!disappeared && !inEditing) 
    {
        [self performSelector: @selector(updateAddress) withObject:nil afterDelay:1.0f];
    }
}

-(void) webViewDidStartLoad:(UIWebView *)webView
{
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
    [UIView setAnimationDuration: 0.2f];
    
    [self.goButton setHidden: YES];
    [self.waitSpinner setHidden: NO];
    
    [UIView commitAnimations];
}

-(void) controlButtons
{
    if ([self.webView canGoBack]) 
    {
        [self.backButton setEnabled: YES];
    }
    else
    {
        [self.backButton setEnabled: NO];
    }
    
    if ([self.webView canGoForward]) 
    {
        [self.nextButton setEnabled: YES];
    }
    else
    {
        [self.nextButton setEnabled: NO];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self.navigationItem setTitle: NSLocalizedString(@"Add station", nil)];
    
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Analyze", nil) style:UIBarButtonItemStyleDone target:self action:@selector(firstAnalyze)] autorelease];
    
    [self.goButton.layer setMasksToBounds: YES];
    [self.goButton.layer setCornerRadius: 3.0f];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey: @"lastUrl"]) 
    {
        [self.webView loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: [[NSUserDefaults standardUserDefaults] objectForKey: @"lastUrl"]]]];
        [self.addressBar setText: [[NSUserDefaults standardUserDefaults] objectForKey: @"lastUrl"]];
    }  
    else
    {
        [self.webView loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: @"http://www.google.com"]]];
        [self.addressBar setText: @"http://www.google.com"];
    }
    
    [self.backButton setEnabled: NO];
    [self.nextButton setEnabled: NO];
    
    [self disableWebViewBouncing:self.webView andScrolling: NO];
    
    [self.waitSpinner startAnimating];
}
                                               

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)disableWebViewBouncing:(UIWebView *)webview andScrolling:(BOOL)disableScrolling
{
    float version = [[[UIDevice currentDevice] systemVersion] floatValue];
    
    if (version >= 5.0)
    {
        webview.scrollView.scrollEnabled = disableScrolling == YES ? NO : YES; 
        webview.scrollView.bounces = NO;
        webview.scrollView.showsVerticalScrollIndicator = NO;
        webview.scrollView.showsHorizontalScrollIndicator = NO;
    }
    else
    {
        for (id subview in webview.subviews)
        {
            if ([[subview class] isSubclassOfClass: [UIScrollView class]])
            {
                [((UIScrollView *)subview) setBounces:NO];
                [((UIScrollView *)subview) setScrollEnabled:(disableScrolling == YES ? NO : YES)];
                
                [((UIScrollView *)subview) setShowsVerticalScrollIndicator:NO];
                [((UIScrollView *)subview) setShowsHorizontalScrollIndicator:NO];
            }
        }
    }
}

@end
