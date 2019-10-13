//
//  ViewController.swift
//  OCR_Demo
//
//  Created by ankit bharti on 09/10/19.
//  Copyright © 2019 ankit kumar bharti. All rights reserved.
//

import UIKit
import VisionKit
import Vision

class ViewController: UIViewController {
    @IBOutlet private weak var messageLabel: UILabel!
    private var textRecognizationRequest = VNRecognizeTextRequest(completionHandler: nil)
    let textRecognitionWorkQueue = DispatchQueue(label: "TextRecognitionQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerTextRecognizationCallback()
    }
    
    @IBAction func launchCamera(_ sender: Any) {
        let controller = VNDocumentCameraViewController()
        controller.delegate = self
        present(controller, animated: true, completion: nil)
    }
    
    private func registerTextRecognizationCallback() {
        self.textRecognizationRequest = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var detectedText = ""
            
            // Vision will separate each line, phrase or sentence automatically into separate observations, which we can iterate over
            for observation in observations {
                // Each observation contains a list of possible 'candidates' that the observation could be, such as ['lol', '1o1', '101']
                // We can ask for all the topCandidates up to a certain limit.
                // Each candidate contains the string and the confidence level that it is accurate.
                guard let topCandidate = observation.topCandidates(1).first else { return }
                detectedText += topCandidate.string
                detectedText += "\n"
            }
            
            DispatchQueue.main.async {
                self.messageLabel.text = detectedText
            }
        }
        
        self.textRecognizationRequest.recognitionLevel = .accurate
        self.textRecognizationRequest.recognitionLanguages = ["en-US"]
    }
    
    private func recognizeText(from image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        textRecognitionWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try requestHandler.perform([self.textRecognizationRequest])
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}


extension ViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print(error.localizedDescription)
        controller.dismiss(animated: true, completion: nil)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        self.recognizeText(from: scan.imageOfPage(at: 0))
        controller.dismiss(animated: true, completion: nil)
    }
}
