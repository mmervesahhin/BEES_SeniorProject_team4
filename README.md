# 🐝 BEES

The Bilkent Educational Exchange for Sustainability (BEES) is a mobile application designed to foster sustainability and resource-sharing within the Bilkent University community. BEES empowers Bilkent University community by providing a secure platform where they can buy, sell, rent, donate or exchange academic materials such as textbooks, calculators, notes, T-squares, and even laptops. This initiative not only reduces the need to purchase new resources but also minimizes waste, promoting a circular economy within the university. BEES is a solution to inefficiencies in material access, tackling both environmental and economic concerns through its innovative approach. Key features of the platform include department-specific searches that allow students to find materials relevant to their field, a built-in auction system for competitive pricing, and dynamic pricing algorithms that adjust based on supply, demand, and condition of the items. BEES's goal is to cultivate a sustainable, collaborative environment that encourages students to make environmentally conscious decisions, while also alleviating the financial pressure that comes with buying new academic materials.

# Coding Standard

This document defines the coding standards used by Team 4 in the BEES Senior Project. All team members are expected to follow this guide to maintain consistency and readability throughout the project.

---

## 📚 Language & Framework
- **Language:** Dart
- **Framework:** Flutter

---

## 📁 Project Architecture
We follow the **MVC (Model-View-Controller)** architectural pattern:
- `models/` → Data classes (e.g., `User`, `Item`, `Request`)
- `controllers/` → Business logic and Firestore operations
- `views/screens/` → UI screens
- `views/widgets/` → Custom reusable widgets
- `utils/` → Colors, constants, formatters, and helpers

---

## 🔤 Naming Conventions

### Files and Folders
- Use `snake_case` for all file and folder names  
  e.g., `home_screen.dart`, `user_model.dart`, `admin_controller.dart`

### Classes
- Use `PascalCase` for class names  
  e.g., `HomeScreen`, `RequestController`, `UserModel`

### Variables and Functions
- Use `camelCase` for variables and function names  
  e.g., `fetchItems()`, `userRating`, `isBanned`

### Constants
- Use `camelCase` for constants  
  e.g., `primaryYellow`, `textDark`

---

## 🎯 Code Formatting

### Indentation
- Use **2 spaces** for indentation (default Flutter formatting)

### Line Length
- Keep lines under 100 characters where possible

### Brackets
- Opening bracket on the same line:
  ```dart
  void fetchData() {
    // ...
  }
