//
//  ViewController.swift
//  RollingClipProject
//
//  Created by Sandeep Kumar on 16/10/21.
//

import UIKit
import ReplayKit
import Photos

class ViewController: UIViewController {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Demo Rolling Clips"
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 29, weight: .bold)
        
        return label
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Start Clip Buffer", for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 3
        
        button.addTarget(self, action: #selector(startScreenRecording), for: .touchUpInside)
        return button
    }()
    
    private let stopButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("Stop Clip Buffer", for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 3
        
        button.addTarget(self, action: #selector(stopScreenRecording), for: .touchUpInside)
        return button
    }()
    
    private let exportClipButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("export Clip Buffer", for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 5
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 3
        
        button.addTarget(self, action: #selector(exportClip), for: .touchUpInside)
        return button
    }()
    
    private let launchViewControllerBtn: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "image1")!, for: .normal)
        button.addTarget(self, action: #selector(openViewController), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        titleLabel.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 100)
        titleLabel.center = view.center
        
        let buttonWidth: CGFloat = 200
        let buttonLeft = CGFloat((view.frame.width - buttonWidth)/2.0)
        let padding = CGFloat(5)
        let buttonHeight = CGFloat(50)
        startButton.frame = CGRect(x: buttonLeft, y: titleLabel.frame.maxY + padding, width: buttonWidth, height: buttonHeight)
        stopButton.frame = CGRect(x: buttonLeft, y: startButton.frame.maxY + padding, width: buttonWidth, height: buttonHeight)
        exportClipButton.frame = CGRect(x: buttonLeft, y: stopButton.frame.maxY + padding, width: buttonWidth, height: buttonHeight)
        
        let launchViewButtonSize = CGFloat(200)
        launchViewControllerBtn.frame = CGRect(x: (view.frame.width - launchViewButtonSize)/2,
                                               y: titleLabel.frame.minY - launchViewButtonSize - 10,
                                               width: launchViewButtonSize,
                                               height: launchViewButtonSize)
        launchViewControllerBtn.layer.cornerRadius = launchViewButtonSize / 2
        launchViewControllerBtn.layer.masksToBounds = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(titleLabel)
        view.addSubview(startButton)
        view.addSubview(stopButton)
        view.addSubview(exportClipButton)
        view.addSubview(launchViewControllerBtn)
        view.backgroundColor = UIColor.init(patternImage: UIImage(named: "background1")!)
    }
    
    @objc private func openViewController() {
        let vc = SomeRandomViewController()
        self.present(vc, animated: true)
    }
}

//MARK: RPRecorder Helpers
extension ViewController{
    @objc private func startScreenRecording() {
        if isRecording() {
            print("Attempting To start recording while recording is in progress")
            return
        }
        if #available(iOS 15.0, *) {
            RPScreenRecorder.shared().startClipBuffering { err in
                if err != nil {
                    print("Error Occured trying to start rolling clip: \(String(describing: err))")
                    //Would be ideal to let the user know about this with an alert
                }
                print("Rolling Clip started successfully")
            }
        }
    }
    
    @objc private func stopScreenRecording() {
        if !isRecording() {
            print("Attempting the stop recording without an on going recording session")
            return
        }
        if #available(iOS 15.0, *) {
            RPScreenRecorder.shared().stopClipBuffering { err in
                if err != nil {
                    print("Failed to stop screen recording")
                    // Would be ideal to let user know about this with an alert
                }
                print("Rolling Clip stopped successfully")
            }
        }
    }
    
    // Provide the URL to which the clip needs to be extracted to
    // Would be preferred to add it to the NSTemporaryDirectory
    @objc private func exportClip() {
        if !isRecording() {
            print("Attemping to export clip while rolling clip buffer is turned off")
            return
        }
        // internal for which the clip is to be extracted
        // Max Value: 15 sec
        let interval = TimeInterval(15)
        
        let clipURL = getDirectory()
        
        print("Generating clip at URL: ", clipURL)
        if #available(iOS 15.0, *) {
            RPScreenRecorder.shared().exportClip(to: clipURL, duration: interval) {[weak self]error in
                if error != nil {
                    print("Error attempting export clip")
                    // would be ideal to show an alert letting user know about the failure
                }
                self?.saveToPhotos(tempURL: clipURL)
            }
        }
    }
    
    private func isRecording() -> Bool {
        return RPScreenRecorder.shared().isRecording
    }
    
    private func getDirectory() -> URL {
        var tempPath = URL(fileURLWithPath: NSTemporaryDirectory())
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-hh-mm-ss"
        let stringDate = formatter.string(from: Date())
        tempPath.appendPathComponent(String.localizedStringWithFormat("output-%@.mp4", stringDate))
        return tempPath
    }
    
    private func saveToPhotos(tempURL: URL) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
        } completionHandler: { success, error in
            if success == true {
                print("Saved rolling clip to photos")
            } else {
                print("Error exporting clip to Photos \(String(describing: error))")
            }
        }
    }
}

