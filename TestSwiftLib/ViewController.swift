//
//  ViewController.swift
//  TestSwiftLib
//
//  Created by SAMATH on 4/13/20.
//  Copyright © 2020 SAMATH. All rights reserved.
//

import UIKit
import WebKit
class ViewController: UIViewController,WKUIDelegate,WKScriptMessageHandler {
    var eventname = "MMSSMH"
    var musicURL = "https://dohreyme.matchmysound.com/lti/start"
    var webView: WKWebView!
    private var isMatchMySound = false
    
    override func loadView() {
       webView = WKWebView(frame: .zero)
               webView.uiDelegate = self
               view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myURL = URL(string:musicURL)
               let myRequest = URLRequest(url: myURL!)
               webView.load(myRequest)
               print("Testing \(myRequest)")
               // the 3 second delay is a hack
               // we want to inject after the redirect has been done
               // should figure out a better way to do that later
               DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: {
                   print("Injecting javascript")
                   
                   let contentController = self.webView.configuration.userContentController
                   contentController.add(self, name: "MMSSMH")
                   
                   let matchMySoundInjectedJS = """
                       var mmsne = {\n\
                       \tcall_haxe:function(fname,args) {\n\
                       \t\t args = args || [];\n\
                       \t\t window.webkit.messageHandlers.MMSSMH.postMessage([fname,JSON.stringify(args)]);\n\
                       \t},\n\
                       \tready:false\n\
                       };\n\
                       \twindow.mmsne.ready=true;\n\
                       \tdocument.dispatchEvent(new Event('mms-ready'));
                       """
    
           
               let injectjs = "var mmsne = {call_haxe:function(fname,args) {args = args || [];window.webkit.messageHandlers.MMSSMH.postMessage([fname,JSON.stringify(args)]);},ready:false};window.addEventListener('load',function() {window.mmsne.ready=true;document.dispatchEvent(new Event('mms-ready'));});console.log('This is log');"
                self.webView.evaluateJavaScript(injectjs, completionHandler: { (result, error) in
                    if (error != nil){
                        print("Testing reuslt: \(result ?? "Samath")")
                    }
                })
                
        })
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let name = message.name
        print("Testing name \(name)")
             let body = message.body
                if body is NSArray {
                    let elems = body as! NSArray
                    let evt = elems[0] as! String
                    let data = elems[1] as! String
                    if evt != nil && data != nil {
                       if !isMatchMySound {
                          initMatchMySound()
                      }
                        let s_evt = String(utf8String: evt)
                        let s_data = String(utf8String: data)
                        call_haxe(s_evt, s_data)
                    }
            }
       }
    
   func initMatchMySound() {
        isMatchMySound = true // setup MatchMySound bridge
        init_mms(matchmysound_dispatcher)
    }
    
    func matchMySoundEvent(_ evt: UnsafePointer<Int8>?, withData data: UnsafePointer<Int8>?) {
        
//        if isVerboseEvent(String(utf8String: evt)) {
//           // print(String(format: "HAXE Event: %s (%ld bytes)", evt, Int(data.length)))
//        }
//
//        if !isFrequentEvent(String(utf8String: evt)) {
//            print("HAXE Event \(evt) : \(data)")
//        }
        
        let s_evt = String(utf8String: evt!)
        let s_data = String(utf8String: data!)

        let pdata = s_data?.data(using: .utf8)
        let b64data = pdata?.base64EncodedString(options: [])

         let trigger = "if(window.trigger) {window.trigger('%@',JSON.parse(atob('%@')));}"

        let fmt = String(utf8String: trigger)
        let js = String(format: fmt!, s_evt ?? "", b64data ?? "")
        webView.evaluateJavaScript(js, completionHandler: { obj, err in
            if err != nil {
                print("HAXE window.trigger('\(s_evt ?? "")') failed: \(err?.localizedDescription ?? "")")
                print("HAXE failed data: \(s_data ?? "")")
            }
        })
    }
    private weak var instance: ViewController?

    private func matchmysound_dispatcher(_ evt: UnsafePointer<Int8>?, _ data: UnsafePointer<Int8>?) {
        autoreleasepool {
            if instance != nil {
                instance?.matchMySoundEvent(evt, withData: data)
            }
        }
    }

    func init_mms(_ event_callback: ((_ event_name: UnsafePointer<Int8>?, _ data: UnsafePointer<Int8>?) -> Void)?) {
           
       }

    func call_haxe(_ function_name: UnsafePointer<Int8>?, _ args: UnsafePointer<Int8>?) {
    }

    func cleanup_mms() {
    }
  
}

