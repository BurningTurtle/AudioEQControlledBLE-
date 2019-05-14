//
//  ViewController.swift
//  AudioVibes
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController {
    var audioVibe : AudioVibes!
    var superpowered:Superpowered!
    var displayLink:CADisplayLink!
    var layers:[CALayer]!
    var magnitudeArray : [UInt16] = [0, 0, 0, 0, 0, 0, 0]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup 8 layers for frequency bars.
        let color:CGColorRef = UIColor(red: 0, green: 0.6, blue: 0.8, alpha: 1).CGColor
        layers = [CALayer(), CALayer(), CALayer(), CALayer(), CALayer(), CALayer(), CALayer(), CALayer()]
        for n in 0...7 {
            layers[n].backgroundColor = color
            layers[n].frame = CGRectZero
            self.view.layer.addSublayer(layers[n])
        }
        
        superpowered = Superpowered()
        
        // A display link calls us on every frame (60 fps).
        displayLink = CADisplayLink(target: self, selector: #selector(ViewController.onDisplayLink))
        displayLink.frameInterval = 1
        displayLink.addToRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    // Gets triggered when you leave the ViewController.
    override func viewWillDisappear(animated: Bool) {
        superpowered.stopPlayback()
        displayLink.invalidate()
        displayLink = nil
        bleLand.disconnectDevice(audioVibe.connection.peripheral)
    }
    
    func onDisplayLink() {
        // Get the frequency values.
        let magnitudes = UnsafeMutablePointer<Float>.alloc(8)
        superpowered.getMagnitudes(magnitudes)
        
        // Wrapping the UI changes in a CATransaction block like this prevents animation/smoothing.
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        CATransaction.setDisableActions(true)
        
        // Set the dimension of every frequency bar.
        let originY:CGFloat = self.view.frame.size.height - 20
        let width:CGFloat = (self.view.frame.size.width - 47) / 5
        var frame:CGRect = CGRectMake(20, 0, width, 0)
        for n in 0...4 {
            frame.size.height = CGFloat(magnitudes[n]) * 1000
            frame.origin.y = originY - frame.size.height
            layers[n].frame = frame
            frame.origin.x += width + 1
        }

        // Set the magnitudes in the array and convert float to UInt16. Magnitudes are between 0.0f and 1.0f
        for n in 0...6 {
            magnitudeArray[n] = UInt16(magnitudes[n] * (65536-1))
        }
        
        // Update the array in the audioVibe class to trigger the sending command.
        audioVibe.magnitudeArray = magnitudeArray
        
        CATransaction.commit()
        
        // Dealloc the magnitudes.
        magnitudes.dealloc(8)
    }
    
}


