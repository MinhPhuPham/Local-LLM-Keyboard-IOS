//
//  KeyboardViewController.swift
//  Custom Keyboard
//
//  Created by Etienne Mueller on 16/8/2024.
//

import UIKit

class KeyboardButton: UIButton {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupButton()
    }
    
    private func setupButton() {
        self.backgroundColor = .lightGray
        self.setTitleColor(.black, for: .normal)
        self.layer.cornerRadius = 5
        self.translatesAutoresizingMaskIntoConstraints = false
    }
}

class KeyboardViewController: UIInputViewController {
    
    var shiftButton: KeyboardButton!
    var backspaceButton: KeyboardButton!
    var customButton: KeyboardButton!
    var isShiftEnabled: Bool = false
    var isSymbolModeEnabled: Bool = false
    var placeholders: [UIView] = []
    var thumbnailView: UIScrollView!
    
    private var model: KeyboardAIModel?
    private var suggestionBar: UIStackView!
    private var predictionCache: [String: [String]] = [:]
    
    // MARK: View Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load model (lazy loading for better performance)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.model = KeyboardAIModel()
            if self?.model == nil {
                print("Failed to initialize model")
            }
        }
        
        // Setup UI
        setupSuggestionBar()
        
        setupLetterButtons()
        setupCustomView()
        isShiftEnabled = true  // Start with the shift key enabled
        updateButtonTitles()   // Apply initial title case
    }

    // MARK: Setup Methods: normal keys
    private func setupLetterButtons() {
        // Clear any existing buttons to avoid overlapping views
        for subview in self.view.subviews {
            if subview is UIButton || subview is KeyboardButton || subview is UIView {
                subview.removeFromSuperview()
            }
        }

        let buttonTitles = isSymbolModeEnabled ? getSymbolButtonTitles() : getLetterButtonTitles()
        
        // Set indentation, left and right margin, spacing between rows per row
        let rowIndentations: [CGFloat] = [0, 0, 0, 0]
        var leftMargins: [CGFloat] = [3, 22, 3, 3]
        var rightMargins: [CGFloat] = [3, 22, 3, 3]
        let rowSpacing: [CGFloat] = [10, 10, 10, 10]
        
        // Adjust margins for the second row in symbol mode
        if isSymbolModeEnabled {
            leftMargins[1] = leftMargins[0]
            rightMargins[1] = rightMargins[0]
        }

        var previousRow: UIView? = nil
        for (index, row) in buttonTitles.enumerated() {
            let isFourthRow = (index == 3)  // Check if it’s the fourth row
            let rowView = createRowOfButtons(titles: row, rowIndentation: rowIndentations[index], isFourthRow: isFourthRow)
            self.view.addSubview(rowView)
            
            // Apply individual left and right margins
            rowView.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: leftMargins[index]).isActive = true
            rowView.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: -rightMargins[index]).isActive = true

            if let previous = previousRow {
                rowView.topAnchor.constraint(equalTo: previous.bottomAnchor, constant: rowSpacing[index]).isActive = true
            } else {
                // Move the keyboard up by reducing the top constraint
                rowView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 5).isActive = true  // Reduced from 15 to 5
            }
            
            previousRow = rowView
        }
        
        updateButtonTitles()  // Apply the initial titles with the correct case
    }
    
    // MARK: Setup Methods: create normal keyboard view
    private func createRowOfButtons(titles: [String], rowIndentation: CGFloat = 0, isFourthRow: Bool = false) -> UIView {
        let rowView = UIView()
        rowView.translatesAutoresizingMaskIntoConstraints = false
        
        var previousButton: UIButton? = nil

        let customGreyColor = UIColor(red: 169/255, green: 175/255, blue: 186/255, alpha: 1.0)
        let customPurpleColor = UIColor(red: 139/255, green: 60/255, blue: 255/255, alpha: 1.0)  // color for the custom button
        
        // Calculate button width based on the maximum number of buttons in any row
        let maxButtonsInRow = 10  // top row has 10 buttons
        let screenWidth = UIScreen.main.bounds.width
        let buttonWidth: CGFloat = screenWidth / CGFloat(Double(maxButtonsInRow) + 1.8)  // +1.8 looks the closest to the stock keyboard
        let buttonHeight: CGFloat = screenWidth / 9  // set button height relative to the screen height
        let buttonFontSize: CGFloat = isFourthRow ? 18 : 22  // font size for the letters on the buttons; fourth row is smaller
        let specialButtonWidth: CGFloat = buttonWidth * 1.35  // make buttons like "shift" and "backspace" wider
        let numberOfSpecialButtons = 4
        let totalSpecialButtonWidth = specialButtonWidth * CGFloat(numberOfSpecialButtons)
        let spaceButtonWidth = screenWidth - totalSpecialButtonWidth - CGFloat(numberOfSpecialButtons + 1) * 6.0  // remaining space for the "space" button
        
        for title in titles {
            let button = KeyboardButton(type: .system)
            
            var currentButtonWidth = buttonWidth
            
            if isFourthRow {
                // Set the custom width for the special buttons and space button
                if title == "123" || title == "ABC" || title == "custom" || title == "return" {
                    if title == "return" {
                        currentButtonWidth = specialButtonWidth * 2  // double width for the return key
                    } else {
                        currentButtonWidth = specialButtonWidth
                    }
                } else if title == "space" {
                    currentButtonWidth = spaceButtonWidth
                }
            } else if isSymbolModeEnabled && ["shift", ".", ",", "?", "!", "'", "backspace"].contains(title) {
                currentButtonWidth = specialButtonWidth  // apply the shift key width to the symbols in symbol mode
            } else {
                if title == "shift" || title == "backspace" {
                    currentButtonWidth = buttonWidth * 1.35  // apply regular width adjustments for other rows
                }
            }
            
            let additionalSpacing: CGFloat = (title == "Z" || title == "backspace" || title == ".") ? 8.8 : 0.0  // apply additional spacing for "Z", "backspace", and "."

            if title == "shift" || title == "backspace" {
                button.setTitle(title == "shift" ? "⇧" : "⌫", for: .normal)
                button.addTarget(self, action: title == "shift" ? #selector(didTapShiftButton) : #selector(didTapBackspaceButton), for: .touchUpInside)
                button.backgroundColor = customGreyColor
                button.setTitleColor(.black, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: buttonFontSize)
            } else if title == "return" {
                button.setTitle("↩︎", for: .normal)  // unicode arrow symbol for return
                button.addTarget(self, action: #selector(didTapReturnButton), for: .touchUpInside)
                button.backgroundColor = customGreyColor
                button.setTitleColor(.black, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: buttonFontSize)
            } else if title == "123" || title == "ABC" {
                button.setTitle(title, for: .normal)
                button.addTarget(self, action: #selector(didTap123Button), for: .touchUpInside)
                button.backgroundColor = customGreyColor
                button.setTitleColor(.black, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: buttonFontSize)
            } else if title == "space" {
                button.setTitle("space", for: .normal)
                button.addTarget(self, action: #selector(didTapSpaceButton), for: .touchUpInside)
                button.backgroundColor = .white
                button.setTitleColor(.black, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: buttonFontSize)
                button.layer.shadowColor = UIColor.black.cgColor
                button.layer.shadowOpacity = 0.3
                button.layer.shadowOffset = CGSize(width: 0, height: 2)
                button.layer.shadowRadius = 1
            } else if title == "custom" {
                button.setTitle("C", for: .normal)
                button.backgroundColor = customPurpleColor
                button.setTitleColor(.white, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: buttonFontSize)
                button.addTarget(self, action: #selector(didTapCustomButton), for: .touchUpInside)
                self.customButton = button
            } else {
                button.setTitle(title, for: .normal)
                button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
                button.backgroundColor = .white
                button.setTitleColor(.black, for: .normal)
                button.titleLabel?.font = UIFont.systemFont(ofSize: buttonFontSize)
                button.layer.shadowColor = UIColor.black.cgColor
                button.layer.shadowOpacity = 0.3
                button.layer.shadowOffset = CGSize(width: 0, height: 2)
                button.layer.shadowRadius = 1
            }
            
            rowView.addSubview(button)
            
            // apply custom height, width, and spacing for each button
            button.topAnchor.constraint(equalTo: rowView.topAnchor).isActive = true
            button.bottomAnchor.constraint(equalTo: rowView.bottomAnchor).isActive = true
            button.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
            button.widthAnchor.constraint(equalToConstant: currentButtonWidth).isActive = true
            
            if let previous = previousButton {
                let spacing: CGFloat = 6.0 + additionalSpacing // Adjust base spacing and add extra if needed
                button.leftAnchor.constraint(equalTo: previous.rightAnchor, constant: spacing).isActive = true
            } else {
                button.leftAnchor.constraint(equalTo: rowView.leftAnchor, constant: rowIndentation + additionalSpacing).isActive = true
            }
            
            previousButton = button
        }
        
        previousButton?.rightAnchor.constraint(equalTo: rowView.rightAnchor).isActive = true
        
        return rowView
    }
    
    // MARK: Setup Methods: Thumbnail View
    // when pressing the custom button
    private func setupCustomView() {
        // initialize the scroll view
        thumbnailView = UIScrollView()
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.isHidden = true
        thumbnailView.backgroundColor = .white  // Set background color to ensure visibility
        self.view.addSubview(thumbnailView)
        
        NSLayoutConstraint.activate([
            thumbnailView.topAnchor.constraint(equalTo: self.view.topAnchor),
            thumbnailView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            thumbnailView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
            thumbnailView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        // create a content view to hold all the elements
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: thumbnailView.topAnchor),
            contentView.leftAnchor.constraint(equalTo: thumbnailView.leftAnchor),
            contentView.rightAnchor.constraint(equalTo: thumbnailView.rightAnchor),
            contentView.bottomAnchor.constraint(equalTo: thumbnailView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: thumbnailView.widthAnchor)  // Width matches scroll view's width
        ])
        
        // add a toolbar at the top
        let toolbar = UIView()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.backgroundColor = UIColor(red: 169/255, green: 175/255, blue: 186/255, alpha: 1.0) // Use custom grey color
        contentView.addSubview(toolbar)
        
        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: contentView.topAnchor),
            toolbar.leftAnchor.constraint(equalTo: contentView.leftAnchor),
            toolbar.rightAnchor.constraint(equalTo: contentView.rightAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // back button
        let backButton = UIButton(type: .system)
        let backImage = UIImage(systemName: "chevron.left")
        backButton.setImage(backImage, for: .normal)
        backButton.addTarget(self, action: #selector(didTapBackButton), for: .touchUpInside)
        toolbar.addSubview(backButton)
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.leftAnchor.constraint(equalTo: toolbar.leftAnchor, constant: 10),
            backButton.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor)
        ])
        
        // list/gellery view toggle
        let viewToggle = UISegmentedControl(items: ["List", "Gallery"])
        viewToggle.selectedSegmentIndex = 0  // Default to List view
        viewToggle.addTarget(self, action: #selector(didChangeViewToggle), for: .valueChanged)
        toolbar.addSubview(viewToggle)
        
        viewToggle.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            viewToggle.centerXAnchor.constraint(equalTo: toolbar.centerXAnchor),
            viewToggle.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor)
        ])
        
        // placeholder setup below the toolbar
        let placeholderCount = 8
        let numberOfColumns = 2
        let padding: CGFloat = 10
        let thumbnailSize: CGFloat = (UIScreen.main.bounds.width - (CGFloat(numberOfColumns + 1) * padding)) / CGFloat(numberOfColumns)
        
        var xOffset: CGFloat = padding
        var yOffset: CGFloat = 44 + padding  // toolbar height
        
        for i in 0..<placeholderCount {
            let placeholder = UIView()
            placeholder.backgroundColor = .white
            placeholder.layer.borderColor = UIColor.gray.cgColor
            placeholder.layer.borderWidth = 1
            placeholder.layer.cornerRadius = 5
            placeholder.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(placeholder)
            
            placeholder.frame = CGRect(x: xOffset, y: yOffset, width: thumbnailSize, height: thumbnailSize)
            
            placeholders.append(placeholder) // add placeholder to the array
            
            if (i + 1) % numberOfColumns == 0 {
                xOffset = padding
                yOffset += thumbnailSize + padding
            } else {
                xOffset += thumbnailSize + padding
            }
        }
        
        // set content size for scrolling based on placeholders
        NSLayoutConstraint.activate([
            contentView.bottomAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset + thumbnailSize + padding)
        ])
    }
    
    @objc func didTapCustomButton(sender: UIButton) {
        // hide the keyboard buttons and show the thumbnail view
        for subview in self.view.subviews where subview !== thumbnailView {
            subview.isHidden = true
        }
        thumbnailView.isHidden = false
        updateForListView()
    }
    
    @objc func didTapBackButton(sender: UIButton) {
        // if thumbnail view is visible, hide it and show the normal keyboard view
        if !thumbnailView.isHidden {
            thumbnailView.isHidden = true
            for subview in self.view.subviews where subview !== thumbnailView {
                subview.isHidden = false
            }
        }
    }

    private func populatePlaceholders(with designs: [[String: Any]]) {
        for (index, design) in designs.prefix(placeholders.count).enumerated() {
            if let name = design["name"] as? String {
                let label = UILabel()
                label.text = name
                label.textAlignment = .center
                label.adjustsFontSizeToFitWidth = true
                placeholders[index].addSubview(label)
                
                label.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: placeholders[index].centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: placeholders[index].centerYAnchor),
                    label.widthAnchor.constraint(equalTo: placeholders[index].widthAnchor, constant: -10)
                ])
            }
        }
    }
    
    // MARK: Button Handling Methods
    @objc func didTapButton(sender: UIButton) {
        let title = sender.title(for: .normal)
        self.textDocumentProxy.insertText(title ?? "")

        // After the first letter is pressed, switch to lowercase (if not in symbol mode)
        if isShiftEnabled && !isSymbolModeEnabled {
            isShiftEnabled = false
            updateButtonTitles()  // Update titles to lowercase
        }
    }
    
    @objc func didTapShiftButton(sender: UIButton) {
        if isSymbolModeEnabled {
            isShiftEnabled.toggle()  // Toggle the Shift state in symbol mode
        } else {
            isShiftEnabled = !isShiftEnabled  // Regular shift toggle in letter mode
        }
        updateButtonTitles()  // Update the titles of the buttons
        setupLetterButtons()  // Refresh the keyboard layout
    }
    
    @objc func didTap123Button(sender: UIButton) {
        if isSymbolModeEnabled {
            // If we're in symbol mode, toggle back to the letter view
            isSymbolModeEnabled = false
        } else {
            // If we're in letter mode, switch to symbol mode
            isSymbolModeEnabled = true
        }

        isShiftEnabled = false  // Reset the shift state when toggling
        setupLetterButtons()  // Refresh the keyboard layout
        updateButtonTitles()  // Update the titles to reflect the new state
    }
    
    @objc func didTapBackspaceButton(sender: UIButton) {
        self.textDocumentProxy.deleteBackward()
    }
    
    @objc func didTapSpaceButton(sender: UIButton) {
        self.textDocumentProxy.insertText(" ")
    }

    @objc func didTapReturnButton(sender: UIButton) {
        self.textDocumentProxy.insertText("\n")
    }
    
    // Utility Methods
    private func getLetterButtonTitles() -> [[String]] {
        return [
            ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
            ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
            ["shift", "Z", "X", "C", "V", "B", "N", "M", "backspace"],
            ["123", "custom", "space", "return"]
        ]
    }
    
    private func getSymbolButtonTitles() -> [[String]] {
        if isShiftEnabled {
            return [
                ["[", "]", "{", "}", "#", "%", "^", "*", "+", "="],
                ["_", "\\", "|", "~", "<", ">", "$", "£", "€", "¥"],
                ["shift", ".", ",", "?", "!", "'", "backspace"],
                ["ABC", "custom", "space", "return"]
            ]
        } else {
            return [
                ["1", "2",  "4", "5", "6", "7", "8", "9", "0"],
                ["-", "/", ":", ";", "(", ")", "$", "&", "@", "\""],
                ["shift", ".", ",", "?", "!", "'", "backspace"],
                ["ABC", "custom", "space", "return"]
            ]
        }
    }
    
    private func updateButtonTitles() {
        let buttonTitles = isSymbolModeEnabled ? getSymbolButtonTitles() : getLetterButtonTitles()
        
        // Flatten the rows to get a list of all buttons
        let buttons = view.subviews.flatMap { $0.subviews }.compactMap { $0 as? UIButton }
        var buttonIndex = 0
        
        for row in buttonTitles {
            for title in row {
                if title == "shift" {
                    // Update the shift button's appearance
                    let shiftButton = buttons[buttonIndex]
                    
                    if isSymbolModeEnabled {
                        if isShiftEnabled {
                            // Change to "123" when in symbol mode with shift enabled
                            shiftButton.setTitle("123", for: .normal)
                            shiftButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
                        } else {
                            // Change to "#+=" in regular symbol mode
                            shiftButton.setTitle("#+=", for: .normal)
                            shiftButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
                        }
                        shiftButton.backgroundColor = UIColor(red: 169/255, green: 175/255, blue: 186/255, alpha: 1.0) // Gray background
                        shiftButton.setTitleColor(.black, for: .normal)
                    } else {
                        // Default appearance in letter mode
                        shiftButton.setTitle("⇧", for: .normal)
                        shiftButton.backgroundColor = isShiftEnabled ? .white : UIColor(red: 169/255, green: 175/255, blue: 186/255, alpha: 1.0)
                        shiftButton.setTitleColor(.black, for: .normal)
                        shiftButton.titleLabel?.font = UIFont.systemFont(ofSize: 22)
                    }
                } else if title == "123" || title == "ABC" {
                    let abcButton = buttons[buttonIndex]
                    if isSymbolModeEnabled {
                        abcButton.setTitle("ABC", for: .normal)  // Show "ABC" in symbol mode
                    } else {
                        abcButton.setTitle("123", for: .normal)  // Show "123" in letter mode
                    }
                    abcButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)  // Set a slightly smaller font size
                } else if title != "backspace" && title != "space" && title != "custom" && title != "return" {
                    let newTitle = isShiftEnabled && !isSymbolModeEnabled ? title.uppercased() : title.lowercased()
                    let fontSize: CGFloat = isShiftEnabled && !isSymbolModeEnabled ? 22 : 24
                    buttons[buttonIndex].setTitle(newTitle, for: .normal)
                    buttons[buttonIndex].titleLabel?.font = UIFont.systemFont(ofSize: fontSize)
                }
                buttonIndex += 1
            }
        }
    }

    // MARK: Custom Page Handling
    private func updateForListView() {
        guard let contentView = thumbnailView.subviews.first else { return }
                
        // Set the background color of the content view
        let contentViewBackgroundColor = UIColor(red: 207/255, green: 211/255, blue: 217/255, alpha: 1.0)
        contentView.backgroundColor = contentViewBackgroundColor
        
        // Clear any existing subviews in contentView (except the toolbar)
        for subview in contentView.subviews where subview !== contentView.subviews.first {
            subview.removeFromSuperview()
        }

        // List view content
        let listItems = ["Item 1", "Item 2", "Item 3", "Item 4", "Item 5", "Item 6", "Item 7", "Item 8"]
        let padding: CGFloat = 10
        var yOffset: CGFloat = 54 + padding  // Adjust for toolbar height + padding

        for item in listItems {
            let label = UILabel()
            label.text = item
            label.textAlignment = .center
            label.backgroundColor = .white  // Ensure list items have a white background
            label.textColor = .black        // Ensure text is black
            label.layer.borderColor = UIColor.gray.cgColor
            label.layer.borderWidth = 1
            label.layer.cornerRadius = 5
            label.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: yOffset),
                label.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: padding),
                label.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -padding),
                label.heightAnchor.constraint(equalToConstant: 44)
            ])
            
            yOffset += 44 + padding
        }

        thumbnailView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: yOffset)
    }
    
    private func updateForGalleryView() {
        guard let contentView = thumbnailView.subviews.first else { return }
                
        // Clear any existing subviews in contentView (except the toolbar)
        for subview in contentView.subviews where subview !== contentView.subviews.first {
            subview.removeFromSuperview()
        }

        // Placeholder setup below the toolbar
        let placeholderCount = 8
        let numberOfColumns = 2
        let padding: CGFloat = 10
        let thumbnailSize: CGFloat = (UIScreen.main.bounds.width - (CGFloat(numberOfColumns + 1) * padding)) / CGFloat(numberOfColumns)
        
        var xOffset: CGFloat = padding
        var yOffset: CGFloat = 54 + padding  // Adjust for toolbar height + padding
        
        for i in 0..<placeholderCount {
            let placeholder = UIView()
            placeholder.backgroundColor = .white
            placeholder.layer.borderColor = UIColor.gray.cgColor
            placeholder.layer.borderWidth = 1
            placeholder.layer.cornerRadius = 5
            contentView.addSubview(placeholder)
            
            placeholder.frame = CGRect(x: xOffset, y: yOffset, width: thumbnailSize, height: thumbnailSize)
            
            if (i + 1) % numberOfColumns == 0 {
                xOffset = padding
                yOffset += thumbnailSize + padding
            } else {
                xOffset += thumbnailSize + padding
            }
        }
        
        thumbnailView.contentSize = CGSize(width: UIScreen.main.bounds.width, height: yOffset + thumbnailSize + padding)
    }
    
    @objc func didChangeViewToggle(sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            updateForListView()
        } else {
            updateForGalleryView()
        }
    }
}

extension KeyboardViewController {
    private func setupSuggestionBar() {
        suggestionBar = UIStackView()
        suggestionBar.axis = .horizontal
        suggestionBar.distribution = .fillEqually
        suggestionBar.spacing = 4
        suggestionBar.backgroundColor = .systemGray6
        
        view.addSubview(suggestionBar)
        
        suggestionBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            suggestionBar.topAnchor.constraint(equalTo: view.topAnchor),
            suggestionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionBar.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    override func textDidChange(_ textInput: UITextInput?) {
        guard let proxy = textDocumentProxy as UITextDocumentProxy?,
              let text = proxy.documentContextBeforeInput,
              !text.isEmpty else {
            clearSuggestions()
            return
        }
        
        updateSuggestions(for: text)
    }
    
    private func updateSuggestions(for text: String) {
        // Check cache first
        if let cached = predictionCache[text] {
            displaySuggestions(cached)
            return
        }
        
        guard let model = model else { return }
        
        // Get predictions in background
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            let suggestions = model.predict(text: text, topK: 3)
            
            // Cache result
            self?.predictionCache[text] = suggestions
            
            // Limit cache size
            if self?.predictionCache.count ?? 0 > 100 {
                self?.predictionCache.removeAll()
            }
            
            DispatchQueue.main.async {
                print("\(#function) suggestions: \(suggestions)")
                self?.displaySuggestions(suggestions)
            }
        }
    }
    
    private func displaySuggestions(_ suggestions: [String]) {
        // Clear existing
        suggestionBar.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Add new suggestions
        for suggestion in suggestions {
            let button = UIButton(type: .system)
            button.setTitle(suggestion, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16)
            button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
            suggestionBar.addArrangedSubview(button)
        }
    }
    
    private func clearSuggestions() {
        suggestionBar.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
    
    @objc private func suggestionTapped(_ sender: UIButton) {
        guard let suggestion = sender.title(for: .normal) else { return }
        textDocumentProxy.insertText(suggestion + " ")
    }
}
