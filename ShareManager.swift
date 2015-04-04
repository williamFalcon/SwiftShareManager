//
//  ShareManager.swift
//  Hac Studios
//
//  Created by William Falcon on 9/6/14.
//  Copyright (c) 2014 Hac Studios. All rights reserved.
//
//  Version: 1.0
//  Description: A class designed to simplify certain sharing actions.
//
//  Supported: - Sharing text (and/or) image through Apple's native share kit
//             - Sending a feedback email through the native mail composer
//

import UIKit
import MessageUI

//sets up a singleton instance
private let _singletonInstance = ShareManager()

class ShareManager: NSObject, MFMailComposeViewControllerDelegate {
    
    //instance properties
    var mailCompletionBlock : ((mailResult: MFMailComposeResult?, error: NSError?) -> Void)?
    var shareCompletionBlock : UIActivityViewControllerCompletionHandler?

    /**
    Singleton Init
    */
    class var sharedInstance: ShareManager {
        return _singletonInstance
    }
    
    class func setShareCompletionHandler(handler:UIActivityViewControllerCompletionHandler?) {
        ShareManager.sharedInstance.shareCompletionBlock = handler
    }
    
    //MARK: - Share sheet
    /*
    Opens up default activity view window (to share) at the bottom of the screen for the app
    */
    class func shareTextImageAndURLFromVC(#sharingText: String?, sharingImage: UIImage?, sharingURL: String?, viewController:UIViewController?) {
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            
            var sharing = [AnyObject]()
            
            if let text = sharingText {
                sharing.append(text)
            }
            if let image = sharingImage {
                sharing.append(image)
            }
            if let url = sharingURL {
                sharing.append(NSURL(string: url)!)
            }
            
            let activityViewController = UIActivityViewController(activityItems: sharing, applicationActivities: nil)
            activityViewController.completionHandler = ShareManager.sharedInstance.shareCompletionBlock
            
            
            if let vc = viewController {
                vc.presentViewController(activityViewController, animated: true, completion: nil)
            }
        })
    }
    
    //MARK: - Mail composer
    /**
    Creates a mail VC to send the feedback email
    */
    class func shareFeedbackFrom(viewController:UIViewController, torecipients recipients:[String], subject:String, message:String, isHTML:Bool, resultCompletion:((mailResult: MFMailComposeResult?, error: NSError?)->())?) {
        
        //build and show mail composer to send feedback
        var mailVC: MFMailComposeViewController = MFMailComposeViewController()
        mailVC.setSubject(subject)
        mailVC.setMessageBody(message, isHTML:isHTML)
        mailVC.setToRecipients(recipients)
        mailVC.mailComposeDelegate = ShareManager.sharedInstance
        
        //track completion for when the mail compose finishes
        ShareManager.sharedInstance.mailCompletionBlock = resultCompletion
        
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            viewController.presentViewController(mailVC, animated: true, completion: nil)
        })
    }
    
    //MARK: - Instance methods
    //MARK: - MFMailComposerDelegate
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        
        //dismiss mail controller
        controller.dismissViewControllerAnimated(true, completion: { () -> Void in
            
            //after dismiss, tell the owner VC the result of the share
            if let mailCompletion = ShareManager.sharedInstance.mailCompletionBlock {
                mailCompletion(mailResult: result, error: error)
            }
        })
    }
}
