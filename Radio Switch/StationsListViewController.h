//
//  StationsListViewController.h
//  Radio Switch
//
//  Created by Olga Dalton on 05/07/2012.
//  Copyright (c) 2012 Olga Dalton. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CategoryListPopup.h"
#import "FixedTextField.h"
#import "BrowserViewController.h"

enum ViewType {
    CategoriesView = 0,
    ListView = 1,
    CustomView = 2,
    RecordedView = 3
    };

@interface StationsListViewController : UIViewController 
                                        <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, UISearchBarDelegate,
                                            UIPickerViewDataSource, UIPickerViewDelegate>
{
    IBOutlet UITableView *tbView;
    
    NSInteger selectedSection;
    
    IBOutlet UISegmentedControl *viewSelector;
    
    enum ViewType currentViewType;
    
    IBOutlet CategoryListPopup *categoryListView;
    
    IBOutlet UIView *pickerMainView;
    IBOutlet UINavigationBar *pickerNavbar;
    IBOutlet UINavigationItem *pickerNavItem;
    
    BOOL pickerVisible;
    
    IBOutlet FixedTextField *stationNameField;
    IBOutlet FixedTextField *stationURLField;
    IBOutlet UIButton *genreButton, *countryButton;
    
    FixedTextField *currentTextField;
    
    BOOL editingInProcess;
    
    IBOutlet UIButton *addStationButton;
    IBOutlet BrowserViewController *analyzingBrowser;
    
    IBOutlet UISearchBar *searchBar;
    
    BOOL searching;
    
    IBOutlet UIPickerView *selectionPicker;
    
    enum PickerType currentPickerType;
    
    IBOutlet UIButton *cancelButton, *selectButton;
    
    int selectedRow;
    
    NSString *lastSelectedCode, *lastSelectedGenre;
    
    BOOL onButton;
}

@property (nonatomic, retain) IBOutlet UITableView *tbView;

@property (nonatomic, retain) IBOutlet BrowserViewController *analyzingBrowser;

@property (nonatomic, retain) IBOutlet UISegmentedControl *viewSelector;

@property (nonatomic, retain) IBOutlet CategoryListPopup *categoryListView;

@property (nonatomic, retain) IBOutlet UIView *pickerMainView;
@property (nonatomic, retain) IBOutlet UINavigationBar *pickerNavbar;
@property (nonatomic, retain) IBOutlet UINavigationItem *pickerNavItem;

@property (nonatomic, retain) IBOutlet FixedTextField *stationNameField;
@property (nonatomic, retain) IBOutlet FixedTextField *stationURLField;
@property (nonatomic, retain) FixedTextField *currentTextField;
@property (nonatomic, retain) IBOutlet UIButton *genreButton, *countryButton;

@property (nonatomic, retain) IBOutlet UIButton *addStationButton;

@property (nonatomic, retain) IBOutlet UISearchBar *searchBar;

@property (nonatomic, retain) IBOutlet UIPickerView *selectionPicker;
@property (nonatomic, retain) IBOutlet UIButton *cancelButton, *selectButton;
@property (nonatomic, retain) NSString *lastSelectedCode, *lastSelectedGenre;

-(IBAction)viewTypeChanged:(id)sender;
-(IBAction)categoryButtonPressed:(id)sender;

-(IBAction) addNewStation: (id) selector;

-(void) showBottomPopup;
-(void)dismissPicker;

-(IBAction)dismissKeyboard:(id)sender;
-(IBAction)editingDidStart:(id)sender;

-(void) urlCheckDone: (NSNumber *) result;

-(IBAction)showGenrePicker:(id)sender;
-(IBAction)showCountryPicker:(id)sender;

-(void) setupPickerViewWithAnimation: (NSNumber *) animated;

-(IBAction)selectPickerTitle:(id)sender;
-(IBAction)cancelPickerTitle:(id)sender;

-(void) desetupPickerView;

@end
