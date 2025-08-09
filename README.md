# Monte Carlo Simulation for Financial Derivatives Pricing (Vlang)

## 📌 Overview
This project implements a **Monte Carlo simulation engine** for pricing complex financial derivatives, written entirely in **Vlang**.  
It supports **vanilla** and **barrier options**, leveraging V’s simplicity, performance, and type safety to produce **accurate and efficient results**.

The simulation is based on the **Black–Scholes–Merton** model and integrates **variance reduction techniques** to improve convergence and reliability.

## 🎯 Key Features
- **Option Types**:
  - Call & Put
  - Barrier options: *Down-and-Out (DO)*, *Down-and-In (DI)*, *Up-and-In (UI)*, *Up-and-Out (UO)*
- **Variance Reduction**:
  - Antithetic variates
  - Control variates
- **Configurable Parameters**:
  - Initial stock price, volatility, strike price
  - Barrier level, risk-free rate, maturity
  - Number of simulations
- **Statistical Output**:
  - 95% confidence intervals for pricing accuracy
- **Performance-Oriented**:
  - Written in V for speed, safety, and maintainability

## 📂 Project Structure
```
.
├── Task1.v          # Core simulation logic
├── Task2.v          # Extended pricing logic
├── new_random.v     # Random number generation utilities
└── README.md        # This file
```

## 🧮 Example Usage
Running the program:
```bash
v run Task1.v
```

Example output:
```
Setting up Monte Carlo Simulation ...
Stock price: 100
Stock volatility: 0.2
Option strike: 100
Option type: Call
Barrier type: DO
Barrier level: 95
Simulations: 10000
Annual Rate: 0.05
Years to Maturity: 1

Estimated option price: 5.11396
95% Confidence Interval: [4.87255, 5.35538]
```

## 📊 Methodology
1. **Model**: Black–Scholes–Merton stochastic differential equation.
2. **Simulation**:
   - Generate asset price paths via Geometric Brownian Motion.
   - Apply barrier knock-in/knock-out conditions when applicable.
3. **Pricing**:
   - Discount simulated payoffs at the risk-free rate.
   - Calculate mean and confidence intervals.

## 🚀 How to Run
### Prerequisites
- [Vlang](https://vlang.io) installed on your system

### Run the simulation
```bash
v run Task1.v
```

### Compile to executable (for faster runs)
```bash
v -prod Task1.v
./Task1
```

## 📈 Applications
- Pricing exotic derivatives for **financial institutions**
- Risk & scenario analysis
- Quantitative finance research

## 📜 License
MIT License
