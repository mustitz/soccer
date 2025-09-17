# Soccer on Paper

An abstract board logic game implementation of the classic paper and pencil game where players draw continuous lines to reach the goal.

## Description

Soccer on Paper is a strategic game played on a grid where players take turns drawing lines from the last position.
The objective is to be the first player to reach the opponent's goal by creating a continuous path.
Each move must continue from where the previous player ended, creating an engaging tactical challenge.

Learn more about the game rules and history: [Paper Soccer on Wikipedia](https://en.wikipedia.org/wiki/Paper_soccer) (see Russian variant).

## Features

- **Basic grid board** with goal areas
- **Turn-based mechanics** with AI opponent (basic implementation)
- **DPI-aware rendering** for consistent sizing across devices
- **Desktop UI** with resizable split-screen layout (very limited MVP)
- **Mobile UI support** (in development)

## Requirements

- **Godot 4.4+** for development
- **Desktop platforms** supported (Windows, macOS, Linux)
- **Mobile platforms** in development

**Status:** Early development stage.
Basic gameplay is functional - you can play against AI on desktop.
Missing essential features like new game, settings, and UI polish.

## Installation & Development

1. **Clone the repository:**
   ```bash
   git clone https://github.com/mustitz/soccer.git
   cd soccer
   git submodule update --init --recursive
   ```

2. **Set up Python environment:**
   Create a new virtual environment or use an existing one with scons.
   Here is an example:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   pip install scons
   ```

3. **Build extensions:**
   ```bash
   cd extensions/engine
   scons
   ```

4. **Open in Godot:**
   - Launch Godot 4.4+
   - Open the project by selecting the `project.godot` file
   - Run the project with F5

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
