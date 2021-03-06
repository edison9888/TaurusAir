//
//  PrepareOrderViewController.m
//  TaurusClient
//
//  Created by Simon on 13-1-12.
//  Copyright (c) 2013年 Taurus. All rights reserved.
//

#import "NSDictionaryAdditions.h"
#import "NSDateAdditions.h"
#import "UIControl+BBlock.h"
#import "BBlock.h"
#import "MBProgressHUD.h"
#import "ALToastView.h"
#import "CRTableViewCell.h"
#import "UIBarButtonItem+ButtonMaker.h"

#import "AppContext.h"
#import "AppConfig.h"
#import "AlixPayHelper.h"
#import "PrepareOrderViewController.h"
#import "FlightSelectViewController.h"
#import "OrderFlightDetailViewController.h"
#import "ThreeCharCode.h"
#import "OrderHelper.h"
#import "TwoCharCode.h"
#import "CharCodeHelper.h"
#import "AirportSearchHelper.h"
#import "ContacterSelectViewController.h"
#import "UIBGNavigationController.h"
#import "InputSendAddressViewController.h"
#import "CRUDViewController.h"
#import "OrderDetailViewController.h"

@interface PrepareOrderViewController () <UITableViewDataSource, UITableViewDelegate>
{
	float					_totalPrice;
	CRTableViewCell*		_isSendAddressCell;
}

@property (nonatomic, retain) IBOutlet UITableView*			orderFormVw;
@property (nonatomic, retain) IBOutlet UILabel*				priceCountLabel;
@property (nonatomic, assign) FlightSelectViewController*	parentVC;
@property (nonatomic, retain) NSMutableDictionary*			passangers;
@property (nonatomic, retain) NSMutableDictionary*			contacter;

- (IBAction)onPlaceOrderButtonTap:(id)sender;

@end

@implementation PrepareOrderViewController

- (void)dealloc
{
	self.orderFormVw = nil;
	self.priceCountLabel = nil;
	self.parentVC = nil;
	self.passangers = nil;
	self.contacter = nil;
	self.sendAddress = nil;
	
	SAFE_RELEASE(_isSendAddressCell);
	
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ORDER_REFRESH" object:nil];
    
	[super dealloc];
}

- (id)initWithFlightSelectVC:(FlightSelectViewController *)aParentVC
{
	if (self = [super init]) {
		self.parentVC = aParentVC;
		
		NSDictionary* cabinInfo = aParentVC.selectedPayInfos[1];
		_totalPrice = [cabinInfo getFloatValueForKey:@"PayPrice" defaultValue:0];
		
		if (aParentVC.viewType == kFlightSelectViewTypeReturn) {
			cabinInfo = aParentVC.parentVC.selectedPayInfos[1];
			_totalPrice += [cabinInfo getFloatValueForKey:@"PayPrice" defaultValue:0];
		}
	}
	
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"PrepareOrderViewController" bundle:nil];
    if (self) {
		self.passangers = [NSMutableDictionary dictionary];
		self.contacter = [NSMutableDictionary dictionary];
		
		_isSendAddressCell = [[CRTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
		_isSendAddressCell.textLabel.text = @"报销凭证";
		_isSendAddressCell.isSelected = NO;
    }
	
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = @"机票预订";
	self.navigationItem.leftBarButtonItem =
        [UIBarButtonItem generateBackStyleButtonWithTitle:@"返回"
                                           andTapCallback:^(id control, UIEvent *event) {
                                               [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ORDER_REFRESH" object:nil];
                                               [self dismissModalViewControllerAnimated:YES];
																			   }];
	
	self.orderFormVw.allowsSelectionDuringEditing = YES;
	self.orderFormVw.editing = YES;
	
	self.priceCountLabel.text = [NSString stringWithFormat:@"￥%d", (int)_totalPrice];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orderReresh:) name:@"ORDER_REFRESH" object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ORDER_REFRESH" object:nil];
}

- (void)orderReresh:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    if(userInfo != nil && [userInfo count] > 0){
        NSString *msg = [userInfo objectForKey:@"MSG"];
        if(msg != nil && (NSNull *)msg != [NSNull null]){
            [ALToastView toastInView:self.view withText:msg andBottomOffset:88 andType:INFOMATION];
        }
    }
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - core methods

- (void)setSendAddress:(NSString *)sendAddress
{
	[sendAddress retain];
	[_sendAddress release];
	_sendAddress = sendAddress;
	
	[self.orderFormVw reloadData];
}

- (void)parseFlightInfoCell:(UITableViewCell*)cell andFlightSelectVC:(FlightSelectViewController*)flightSelectVC
{
	// @[flightInfo, cabin1]
	NSDictionary* flightInfo = flightSelectVC.selectedPayInfos[0];
	NSDictionary* cabinInfo = flightSelectVC.selectedPayInfos[1];
	
	UIImageView* departureOrReturnImgVw = (UIImageView*)[cell viewWithTag:100];
	UILabel* departureOrReturnLabel = (UILabel*)[cell viewWithTag:101];
	UILabel* dateLabel = (UILabel*)[cell viewWithTag:102];
	UILabel* twoCharLabel = (UILabel*)[cell viewWithTag:103];
	UILabel* purePriceLabel = (UILabel*)[cell viewWithTag:104];
	UILabel* otherPriceLabel = (UILabel*)[cell viewWithTag:105];
	UILabel* durationTimeLabel = (UILabel*)[cell viewWithTag:106];
	UILabel* departureAirportLabel = (UILabel*)[cell viewWithTag:107];
	UILabel* arrivalAirportLabel = (UILabel*)[cell viewWithTag:108];
	UIButton* viewAirplaneDetailBtn = (UIButton*)[cell viewWithTag:109];
	UIButton* viewReturnTicketDetailBtn = (UIButton*)[cell viewWithTag:110];
	
	// departureOrReturnImgVw
	if (flightSelectVC.viewType == kFlightSelectViewTypeReturn) {
		departureOrReturnImgVw.image = [UIImage imageNamed:@"order_return_btn_bg.png"];
		departureOrReturnLabel.text = @"返程";
	}
	
	NSDate* leaveTime = [NSDate dateFromString:[flightInfo getStringValueForKey:@"LeaveTime" defaultValue:@""]];
	NSDate* arriveTime = [NSDate dateFromString:[flightInfo getStringValueForKey:@"ArriveTime" defaultValue:@""]];

	// dateLabel
	dateLabel.text = [leaveTime stringWithFormat:@"yyyy-MM-dd"];
	
	// twoCharLabel
	NSString* twoCharcodeStr = [flightInfo getStringValueForKey:@"Ezm" defaultValue:@""];
	NSString* flightNumStr = [flightInfo getStringValueForKey:@"FlightNum" defaultValue:@""];
	TwoCharCode* twoCharcode = [AirportSearchHelper queryWithTwoCharCodeString:twoCharcodeStr];
	
	twoCharLabel.text = [NSString stringWithFormat:@"%@%@", twoCharcode.corpAbbrName, flightNumStr];

	// purePriceLabel
	float purePrice = [cabinInfo getFloatValueForKey:@"DiscountPrice" defaultValue:0]
	- [cabinInfo getFloatValueForKey:@"CommissionPrice" defaultValue:0];
	
	purePriceLabel.text = [NSString stringWithFormat:@"￥%d", (int)purePrice];
	
	// otherPrice
//	float otherPrice = [flightInfo getFloatValueForKey:@"ConsCosts" defaultValue:0]
//	+ [flightInfo getFloatValueForKey:@"FuelCosts" defaultValue:0];
//	
//	otherPriceLabel.text = [NSString stringWithFormat:@"￥%.2f", otherPrice];
	
	otherPriceLabel.text = [NSString stringWithFormat:@"￥%d/%d"
							, (int)[flightInfo getFloatValueForKey:@"ConsCosts" defaultValue:0]
							, (int)[flightInfo getFloatValueForKey:@"FuelCosts" defaultValue:0]];
	
	// durationTimeLabel
	durationTimeLabel.text = [NSString stringWithFormat:@"%@      -      %@"
							  , [leaveTime stringWithFormat:@"HH:mm"]
							  , [arriveTime stringWithFormat:@"HH:mm"]];
	
	// departureAirportLabel
	NSDictionary* threeCodes = [CharCodeHelper allThreeCharCodesDictionary];

	NSString *fromTo = [flightInfo getStringValueForKey:@"FromTo" defaultValue:@""];
    ThreeCharCode *from = [threeCodes objectForKey:[fromTo substringToIndex:3]];
    ThreeCharCode *to = [threeCodes objectForKey:[fromTo substringFromIndex:3]];
	NSString* airportTower = [flightInfo getStringValueForKey:@"AirportTower" defaultValue:@""];
	NSString* fromAirportTower = [airportTower substringToIndex:[airportTower rangeOfString:@" "].location];
	NSString* toAirportTower = [airportTower substringFromIndex:[airportTower rangeOfString:@" "].location];
	NSString* fromAirportFullName = [NSString stringWithFormat:@"%@ %@"
									 , from.airportAbbrName
									 , fromAirportTower];
	
	departureAirportLabel.text = fromAirportFullName;
	
	// arrivalAirportLabel
	NSString* toAirportFullName = [NSString stringWithFormat:@"%@ %@"
								   , to.airportAbbrName
								   , toAirportTower];
	arrivalAirportLabel.text = toAirportFullName;
	
	// viewAirplaneDetailBtn
	[viewAirplaneDetailBtn
	 addActionForControlEvents:UIControlEventTouchUpInside
	 withBlock:^(id control, UIEvent *event) {
		 // @[@"航空公司", @"航班", @"舱位", @"出发机场", @"出发时间", @"到达机场", @"到达时间"]]
		 OrderFlightDetailViewController* vc = [[OrderFlightDetailViewController alloc] init];
		 
		 vc.detail = @[
		 twoCharcode.corpAbbrName
		 , flightNumStr
		 , [cabinInfo getStringValueForKey:@"CabinName" defaultValue:@""]
		 , fromAirportFullName
		 , [leaveTime stringWithFormat:@"yyyy-MM-dd HH:mm"]
		 , toAirportFullName
		 , [arriveTime stringWithFormat:@"yyyy-MM-dd HH:mm"]
		 ];
		 
		 [self.navigationController pushViewController:vc animated:YES];
		 SAFE_RELEASE(vc);
	 }];
	
	// viewReturnTicketDetailBtn
	[viewReturnTicketDetailBtn
	 addActionForControlEvents:UIControlEventTouchUpInside
	 withBlock:^(id control, UIEvent *event) {
         CRUDViewController *vc = [[CRUDViewController alloc] init];
         vc.cabin = [cabinInfo getStringValueForKey:@"CabinName" defaultValue:@""];
         vc.ezm = [flightInfo getStringValueForKey:@"Ezm" defaultValue:@""];
         [self.navigationController pushViewController:vc animated:YES];
         [vc release];
	 }];
}

#pragma mark - actions

- (IBAction)onPlaceOrderButtonTap:(id)sender
{
	// 检查联系人是否为空
	if (self.passangers.count == 0 || self.contacter.count == 0) {
//		UIAlertView* alertVw = [[UIAlertView alloc] initWithTitle:nil
//														  message:@"请选择联系人与乘客。"
//														 delegate:nil
//												cancelButtonTitle:@"我知道了"
//												otherButtonTitles:nil];
		
		[ALToastView toastInView:self.view withText:@"请选择联系人与乘客。" andBottomOffset:44 andType:ERROR];
		
//		[alertVw show];
//		SAFE_RELEASE(alertVw);
		
		return;
	}
	
//	[[NSNotificationCenter defaultCenter] postNotificationName:@"ALIXPAY_CALLBACK_SUCCESS" object:nil];
//
//	return;
//
//	// 订购
//	[OrderHelper performOrderWithPassangers:self.passangers
//							   andContactor:self.contacter
//							 andSendAddress:self.sendAddress
//			  andFlightSelectViewController:self.parentVC
//								  andInView:self.view
//								   andPrice:_totalPrice
//							 andProductName:@"机票"
//							 andProductDesc:@"机票"];
	
	FlightSelectViewController* vc = self.parentVC;
	NSArray* flightInfos = vc.viewType == kFlightSelectViewTypeReturn
	? @[vc.parentVC.selectedPayInfos[0], vc.selectedPayInfos[0]]
	: @[vc.selectedPayInfos[0]];
	
	NSArray* cabinInfo = vc.viewType == kFlightSelectViewTypeReturn
	? @[vc.parentVC.selectedPayInfos[1], vc.selectedPayInfos[1]]
	: @[vc.selectedPayInfos[1]];
	
	MBProgressHUD* hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
	hud.labelText = @"正在提交订单...";
	
	[OrderHelper performPlaceOrderWithUser:[AppConfig get].currentUser
							 andFlightInfo:flightInfos
								  andCabin:cabinInfo
							  andTravelers:[self.passangers allValues]
							  andContactor:self.contacter
							andSendAddress:_isSendAddressCell.isSelected ? self.sendAddress : @""
								   success:^(NSDictionary * respObj) {
									   [MBProgressHUD hideHUDForView:self.view
															animated:YES];
									   
									   int orderId = [respObj getIntValueForKey:@"Response" defaultValue:0];
									   
									   // TODO:
									   //orderId = 6820843;
									   
									   [self dismissModalViewControllerAnimated:NO];
									   
									   OrderDetailViewController *vc = [[OrderDetailViewController alloc] init];
									   [vc setOrderListItem:@{@"Tid":[NSString stringWithFormat:@"%d", orderId]}];
									   
									   [vc setPayButtonTapBlock:^{
										   [AlixPayHelper performAlixPayWithOrderId:[NSString stringWithFormat:@"%d", orderId]
																	 andProductName:@"机票"
																	 andProductDesc:@"机票"
																	andProductPrice:_totalPrice
																	  andPassangers:self.passangers
																	   andContactor:self.contacter
													  andFlightSelectViewController:self.parentVC
																	 andOrderDetail:nil];
									   }];
									   
									   UIBGNavigationController *nav = [[UIBGNavigationController alloc] initWithRootViewController: vc];
									   [self.parentVC presentModalViewController:nav animated:YES];
									   [vc release];
									   [nav release];
								   }
								   failure:^(NSString * errorMsg) {
									   [MBProgressHUD hideHUDForView:self.view
															animated:YES];
									   
									   [ALToastView toastInView:self.view
													   withText:errorMsg
												andBottomOffset:44.0f
														andType:ERROR];
								   }];
}

#pragma mark - tableview delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (self.parentVC.viewType == kFlightSelectViewTypeReturn)
		return 5;
	else
		return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self.parentVC.viewType == kFlightSelectViewTypeReturn) {
		if (section == 0)
			return 1;
		else if (section == 1)
			return 1;
		else if (section == 2)
			return 1 + (self.passangers.count);
		else if (section == 3)
			return 1;
		else
			return 1;
	} else {
		if (section == 0)
			return 1;
		else if (section == 1)
			return 1 + (self.passangers.count);
		else if (section == 2)
			return 1;
		else
			return _isSendAddressCell.isSelected ? 2 : 1;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	int section = indexPath.section;
	
	if (self.parentVC.viewType == kFlightSelectViewTypeReturn) {
		if (section == 0)
			return 182;
		else if (section == 1)
			return 182;
		else if (section == 2)
			return 44;
		else if (section == 3)
			return 44;
		else
			return 44;
	} else {
		if (section == 0)
			return 182;
		else if (section == 1)
			return 44;
		else if (section == 2)
			return 44;
		else
			return 44;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	int offset = self.parentVC.viewType == kFlightSelectViewTypeReturn ? -1 : 0;
	section = section + offset;
	
	if (section == 1) {
		return @"乘客";
	} else if (section == 2) {
		return @"联系人";
	} else if (section == 3) {
		return @"报销凭证";
	}
	
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	int offset = self.parentVC.viewType == kFlightSelectViewTypeReturn ? -1 : 0;
	int section = indexPath.section + offset;
	UITableViewCell* cell;
	
	if (section == -1) {
		cell = [[NSBundle mainBundle] loadNibNamed:@"PrepareOrderCells" owner:nil options:nil][0];
		[self parseFlightInfoCell:cell andFlightSelectVC:self.parentVC.parentVC];
	} else if (section == 0) {
		cell = [[NSBundle mainBundle] loadNibNamed:@"PrepareOrderCells" owner:nil options:nil][0];
		[self parseFlightInfoCell:cell andFlightSelectVC:self.parentVC];
	} else if (section == 1) {
		if (indexPath.row == 0)
			cell = [[NSBundle mainBundle] loadNibNamed:@"PrepareOrderCells" owner:nil options:nil][1];
		else {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
			NSArray* values = [self.passangers allValues];
			NSDictionary* dic = [values objectAtIndex:indexPath.row - 1];
			
//			NSLog(@"dic%@", dic);
			
			NSString* name = [dic getStringValueForKey:@"Name" defaultValue:nil];
			cell.textLabel.text = name;
		}
	} else if (section == 2) {
		if (self.contacter.count == 0) {
			cell = [[NSBundle mainBundle] loadNibNamed:@"PrepareOrderCells" owner:nil options:nil][2];
		} else {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
			
			NSString* name = [[self.contacter allValues][0] getStringValueForKey:@"Name" defaultValue:nil];
			cell.textLabel.text = name;
		}
	} else {
		if (indexPath.row == 0)
			return _isSendAddressCell;
		
		if (self.sendAddress.length > 0) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil] autorelease];
			cell.textLabel.text = self.sendAddress;
		} else {
			cell = [[NSBundle mainBundle] loadNibNamed:@"PrepareOrderCells" owner:nil options:nil][3];
		}
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	int offset = self.parentVC.viewType == kFlightSelectViewTypeReturn ? -1 : 0;
	int section = indexPath.section + offset;

	if (section == 1) {
		ContacterSelectViewController *vc = [[ContacterSelectViewController alloc] initWithSelectType:SelectTypePassenger
																				   defaultSeletedData:self.passangers];
		
		[vc setCompletionBlock:^(NSMutableDictionary *selectedPersons) {
			self.passangers = selectedPersons;
			[self.orderFormVw reloadData];
		}];
		
		UIBGNavigationController *nv = [[UIBGNavigationController alloc] initWithRootViewController:vc];
		[vc release];
		[self presentModalViewController:nv animated:YES];
		[nv release];
	} else if (section == 2) {
		ContacterSelectViewController *vc = [[ContacterSelectViewController alloc] initWithSelectType:SelectTypeContacter
																				   defaultSeletedData:self.contacter];
		
		[vc setCompletionBlock:^(NSMutableDictionary *selectedPersons) {
			self.contacter = selectedPersons;
			
			// 判断sendAddress，填写联系人的Address字段
			if (self.sendAddress.length == 0)
				self.sendAddress = [[self.contacter allValues][0] getStringValueForKey:@"Address" defaultValue:@""];
			
			[self.orderFormVw reloadData];
		}];
		
		UIBGNavigationController *nv = [[UIBGNavigationController alloc] initWithRootViewController:vc];
		[vc release];
		[self presentModalViewController:nv animated:YES];
		[nv release];
	} else if (section == 3) {
		if (indexPath.row == 0) {
			_isSendAddressCell.isSelected = !_isSendAddressCell.isSelected;
			[tableView reloadData];
		} else {
			InputSendAddressViewController* vc = [[InputSendAddressViewController alloc] initWithParentVC:self];
			vc.sendAddress = self.sendAddress;
			
			UIBGNavigationController *nv = [[UIBGNavigationController alloc] initWithRootViewController:vc];
			[vc release];
			[self presentModalViewController:nv animated:YES];
			[nv release];
		}
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	int offset = self.parentVC.viewType == kFlightSelectViewTypeReturn ? -1 : 0;
	int section = indexPath.section + offset;
	
	if (section == 1) {
		if (indexPath.row != 0)
			return UITableViewCellEditingStyleDelete;
	} else if (section == 2) {
		if (self.contacter.count != 0)
			return UITableViewCellEditingStyleDelete;
	}
	
	return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1) {
		// 删除乘客
		int index = indexPath.row - 1;
		NSArray* keys = [self.passangers allKeys];
		NSString* key = keys[index];
		
		[self.passangers removeObjectForKey:key];
		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	} else if (indexPath.section == 2) {
		// 删除联系人
//		int index = indexPath.row;
		
		self.contacter = [NSMutableDictionary dictionary];
//		[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
		[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	}
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	int offset = self.parentVC.viewType == kFlightSelectViewTypeReturn ? -1 : 0;
	int section = indexPath.section + offset;
	
	if (section == 1) {
		if (indexPath.row != 0)
			return NO;
	} else if (section == 2) {
		if (self.contacter.count != 0)
			return NO;
	}
	
	return NO;
}

@end
