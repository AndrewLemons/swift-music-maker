/*
    Created by Andrew Lemons 2020
*/

import PlaygroundSupport
import UIKit
import AVFoundation

let t: Double = 1000000 // t is seconds
let noteNames: [String] = [
    "C2", //    0
    "B1", //    1
    "A1", //    2
    "G1", //    3
    "F1", //    4
    "E1", //    5
    "D1", //    6
    "C1", //    7
    "Snare", // 8
    "Bass" //   9
]
let colors: [UIColor] = [
    #colorLiteral(red: 1, green: 0.2705882353, blue: 0.2274509804, alpha: 1),#colorLiteral(red: 1, green: 0.6235294118, blue: 0.03921568627, alpha: 1),#colorLiteral(red: 1, green: 1, blue: 0, alpha: 1),#colorLiteral(red: 0.1960784314, green: 0.8431372549, blue: 0.2941176471, alpha: 1),#colorLiteral(red: 0.3921568627, green: 0.8235294118, blue: 1, alpha: 1),#colorLiteral(red: 0.03921568627, green: 0.5176470588, blue: 1, alpha: 1),#colorLiteral(red: 0.368627451, green: 0.3607843137, blue: 0.9019607843, alpha: 1),#colorLiteral(red: 1, green: 0.2705882353, blue: 0.2274509804, alpha: 1),
    #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1),#colorLiteral(red: 0.1215686277, green: 0.01176470611, blue: 0.4235294163, alpha: 1)
]

class MusicMaker : UIViewController {
    // Player
    var soundsLoaded = false
    var playing = false
    
    // Song
    var notePlayers: [AVAudioPlayer] = []
    var song: [[Int]] = [[], [], [], [], []]
    var tempo: Double = 0.6
    
    // Grid
    var gridViews: [Coord : UIView] = [:]
    var gridLines: [UIView] = []
    var gridHeight = 0
    var gridWidth = 0
    
    // Controls
    let playButton = UIButton()
    let pauseButton = UIButton()
    let lengthStepper = UIStepper()

    // Text
    let lengthDisplay: UILabel = UILabel()
    let tempoDisplay: UILabel = UILabel()
    
    override func loadView() {
        // Update the grid sizing
        gridHeight = Int(450 / noteNames.count)
        gridWidth = Int(400 / song.count)
        
        // Load the sounds so we know what to display
        loadSounds()
        
        // Start creating the view
        let view = UIView()
        view.backgroundColor = .white
        view.frame = CGRect(x: 0, y: 0, width: 400, height: 500)
        
        // Create the tool bar
        let toolbar = UIView()
        toolbar.frame = CGRect(x: 0, y: 450, width: 400, height: 50)
        toolbar.backgroundColor = .lightGray
        view.addSubview(toolbar)
        
        // Create the play button
        let playButtonImage = UIImage(systemName: "play.circle")
        playButton.setImage(playButtonImage, for: .normal)
        playButton.frame = CGRect(x: 0, y: 0, width: 25, height: 50)
        playButton.addTarget(self, action: #selector(playSong), for: .touchUpInside)
        toolbar.addSubview(playButton)
        
        // Create the pause button
        let pauseButtonImage = UIImage(systemName: "pause.circle")
        pauseButton.isEnabled = false
        pauseButton.setImage(pauseButtonImage, for: .normal)
        pauseButton.frame = CGRect(x: 25, y: 0, width: 25, height: 50)
        pauseButton.addTarget(self, action: #selector(pauseSong), for: .touchUpInside)
        toolbar.addSubview(pauseButton)
        
        // Create length changer
        let lengthLabel = UILabel()
        lengthLabel.text = "Length"
        lengthLabel.frame = CGRect(x: 160, y: 5, width: 100, height: 20)
        toolbar.addSubview(lengthLabel)
        
        lengthDisplay.text = "5"
        lengthDisplay.textColor = .systemBlue
        lengthDisplay.frame = CGRect(x: 160, y: 25, width: 100, height: 20)
        toolbar.addSubview(lengthDisplay)
        
        lengthStepper.center = CGPoint(x: 110, y: 25)
        lengthStepper.addTarget(self, action: #selector(changeLength), for: .valueChanged)
        lengthStepper.value = 5
        lengthStepper.minimumValue = 2
        lengthStepper.maximumValue = 25
        lengthStepper.stepValue = 1
        toolbar.addSubview(lengthStepper)
        
        // Create tempo changer
        let tempoLabel = UILabel()
        tempoLabel.text = "Tempo"
        tempoLabel.frame = CGRect(x: 330, y: 5, width: 100, height: 20)
        toolbar.addSubview(tempoLabel)
        
        tempoDisplay.text = "100"
        tempoDisplay.textColor = .systemBlue
        tempoDisplay.frame = CGRect(x: 330, y: 25, width: 100, height: 20)
        toolbar.addSubview(tempoDisplay)
        
        let tempoStepper = UIStepper()
        tempoStepper.center = CGPoint(x: 280, y: 25)
        tempoStepper.addTarget(self, action: #selector(changeTempo), for: .valueChanged)
        tempoStepper.value = 100
        tempoStepper.minimumValue = 50
        tempoStepper.maximumValue = 240
        tempoStepper.stepValue = 5
        toolbar.addSubview(tempoStepper)
        
        // Create vertical the grid lines
        for (x, _) in song.enumerated() {
            let line = UIView()
            line.layer.borderColor = UIColor.lightGray.cgColor
            line.layer.borderWidth = 1
            line.backgroundColor = .clear
            line.frame = CGRect(x: x * gridWidth, y: 0, width: gridWidth, height: 450)
            gridLines.append(line)
            view.addSubview(line)
        }
        
        // Create the horizontal grid lines
        for (index, note) in noteNames.enumerated() {
            let line = UILabel()
            line.text = note
            line.textColor = .lightGray
            line.layer.borderColor = UIColor.lightGray.cgColor
            line.layer.borderWidth = 1
            line.frame = CGRect(x: 0, y: index * gridHeight, width: 400, height: gridHeight)
            view.addSubview(line)
        }
        
        // Create a return view to act like a container if the screen size is not correct (let's hope it is)
        let returnView = UIView()
        returnView.backgroundColor = .black
        returnView.addSubview(view)
        self.view = returnView
    }
    
    // Change the current length of the song
    @objc func changeLength(sender: UIStepper) {
        // Get the target length
        let targetLength = Int(sender.value)
        
        // Set the length
        if targetLength > song.count {
            while targetLength > song.count {
                song.append([])
            }
        } else {
            while targetLength < song.count {
                song.removeLast()
            }
        }
        
        // Update the grid sizing
        gridHeight = Int(450 / noteNames.count)
        gridWidth = Int(400 / song.count)
        
        // Update the display text and grid
        lengthDisplay.text = "\(sender.value)"
        updateGridView()
    }
    
    @objc func changeTempo(sender: UIStepper) {
        // calculate the tempo
        let bps = sender.value / 60
        tempo = 1 / bps
        
        // Update the display
        tempoDisplay.text = "\(sender.value)"
    }
    
    @objc func pauseSong(sender: UIButton) {
        // Pause the song
        playing = false
        
        // Set controls states
        lengthStepper.isEnabled = true
        playButton.isEnabled = true
        pauseButton.isEnabled = false
    }
    
    @objc func playSong(sender: UIButton) {
        // Don't play if already playing
        if playing {
            return
        }
        
        // Set the song state to playing
        self.playing = true
        
        // Set control states
        lengthStepper.isEnabled = false
        pauseButton.isEnabled = true
        playButton.isEnabled = false
        
        // Play the song async
        DispatchQueue.global().async {
            // Wait .25 seconds before playing
            usleep(useconds_t(t * 0.25))
            
            var index = 0
            
            // Loop the song
            while self.playing {
                // Get the notes to play
                let notes = self.song[index]
                
                // Play the notes
                self.playNotes(indexes: notes)
                
                // Update the index
                index += 1
                if index >= self.song.count {
                    index = 0
                }
                
                // Wait
                usleep(useconds_t(t * self.tempo))
            }
        }
    }
    
    func playNotes(indexes: [Int]) {
        // Stop already playing notes
        for i in indexes {
            self.notePlayers[i].stop()
            self.notePlayers[i].currentTime = 0
            self.notePlayers[i].prepareToPlay()
        }

        // Play the notes
        for i in indexes {
            self.notePlayers[i].play()
        }
    }
    
    func loadSounds() {
        // Don't load the sounds if they are already loaded
        if soundsLoaded {
            return
        }
        
        // Get the URLs
        for name in noteNames {
            do {
                let url = URL(fileURLWithPath: Bundle.main.path(forResource: name, ofType: "mp3")!)
                notePlayers.append(try AVAudioPlayer(contentsOf: url))
            } catch {
                print("Sounds failed to load.")
            }
        }
        
        // The sounds are now loaded!
        soundsLoaded = true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            // Get the touch positon
            let position = touch.location(in: view)
            
            // Make sure the touch is in the display area
            if position.y < 450 && position.x < 400 {
                // Round the position to the grid
                let posX = roundToGrid(pos: Int(position.x), size: gridWidth)
                let posY = roundToGrid(pos: Int(position.y), size: gridHeight)
                
                // Dont do it if it is over the song length
                if posX / gridWidth >= song.count {
                    return
                }
                
                // Update the grid tile
                manageGridPress(x: posX/gridWidth, y: posY/gridHeight)
            }
        }
    }
    
    func manageGridPress(x: Int, y: Int) {
        // Add the correct row
        let firstIndex = song[x].firstIndex(of: y)
        if firstIndex != nil {
            song[x].remove(at: firstIndex!)
        } else {
            song[x].append(y)
        }
        
        // Remove duplicates
        song[x].removeDuplicates()
        
        // Update the views
        updateGridView(x: x, y: y)
    }
    
    func updateGridView(x: Int, y: Int) {
        if song[x].contains(y) {
            // Add a new grid tile
            if gridViews.index(forKey: Coord(x: x, y: y)) == nil {
                let newView = UIView()
                newView.backgroundColor = colors[y]
                newView.frame = CGRect(x: x * gridWidth, y: y * gridHeight, width: gridWidth, height: gridHeight)
                view.addSubview(newView)
                gridViews[Coord(x: x, y: y)] = newView
            }
        } else {
            // Remove a grid tile
            gridViews[Coord(x: x, y: y)]?.removeFromSuperview()
            gridViews.removeValue(forKey: Coord(x: x, y: y))
        }
    }
    
    func updateGridView() {
        // Remove all tiles
        for note in gridViews {
            note.value.removeFromSuperview()
        }
        gridViews.removeAll()
        
        // Update the grid lines
        if gridLines.count > song.count {
            gridLines.last!.removeFromSuperview()
            gridLines.removeLast()
        } else {
            let line = UIView()
            line.layer.borderColor = UIColor.lightGray.cgColor
            line.layer.borderWidth = 1
            line.backgroundColor = .clear
            gridLines.append(line)
            view.addSubview(line)
        }
        
        // Update the grid lines
        for (x, line) in gridLines.enumerated() {
            line.frame = CGRect(x: x * gridWidth, y: 0, width: gridWidth, height: 450)
        }
        
        // Add the new tiles
        for (x, notes) in song.enumerated() {
            for note in notes {
                let newView = UIView()
                newView.backgroundColor = colors[note]
                newView.frame = CGRect(x: x * gridWidth, y: note * gridHeight, width: gridWidth, height: gridHeight)
                view.addSubview(newView)
                gridViews[Coord(x: x, y: note)] = newView
            }
        }
    }
}

func roundToGrid(pos: Int, size: Int) -> Int {
    // Round the position to the grid based on its size
    let divided = floor(Double(pos / size))
    let rounded = Int(divided) * size
    return rounded
}

struct Coord: Hashable {
    var x: Int
    var y: Int
    
    init(x: Int, y: Int) {
        self.x = x
        self.y = y
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        // Remove all duplicate items in the array
        var addedDict = [Element: Bool]()
        
        return filter {
            addedDict.updateValue(true, forKey: $0) == nil
        }
    }
    
    mutating func removeDuplicates() {
        self = self.removingDuplicates()
    }
}

// Create the view and display it
var mainMusicMaker = MusicMaker()
mainMusicMaker.preferredContentSize = CGSize(width: 400, height: 500)
mainMusicMaker.view.frame = CGRect(x: 0, y: 0, width: 400, height: 500);
PlaygroundPage.current.liveView = mainMusicMaker
