module main

import os
import random_module
import math
import strconv
import progressbar
import time

struct Stock {
		price f64
		volatility f64
}

struct BarrierOption {
		strike f64
		opt_type string
		barrier_type string
		barrier f64
		simulations u64
}

struct RiskFreeAsset {
		rate f64
		ytd f64
}

fn main() {
	redo_inputs: // Pointers jumps here if inputs are invalid.
	stock,option,riskfree := setup()
	drift := riskfree.rate - (math.pow(stock.volatility,2))/2
	steps := math.round(252*riskfree.ytd)
	dt := riskfree.ytd/steps

	z := chan f64{cap: 1000} // A thread keeping a buffert containing 10000 random numbers all the time
	go random_module.randn_sobol(z, steps)

	mut options := []f64{}
	if option.barrier_type == 'DO' && option.opt_type == 'Call' {
		// Price Down and Out Call option
		options = do_call(stock, option, riskfree, drift, steps, dt, z)
	}
	else if option.barrier_type == 'DO' && option.opt_type == 'Put' {
		// Price Down and Out Put option
		options = do_put(stock, option, riskfree, drift, steps, dt, z)
	}
	else if option.barrier_type == 'DI' && option.opt_type == 'Call' {
		// Price Down and In Call option
		options = di_call(stock, option, riskfree, drift, steps, dt, z)
	}
	else if option.barrier_type == 'DI' && option.opt_type == 'Put' {
		// Price Down and In Put option
		options = di_put(stock, option, riskfree, drift, steps, dt, z)
	}
	else if option.barrier_type == 'UI' && option.opt_type == 'Call' {
		// Price Up and In Call option
		options = ui_call(stock, option, riskfree, drift, steps, dt, z)
	}
	else if option.barrier_type == 'UI' && option.opt_type == 'Put' {
		// Price Up and In Put option
		options = ui_put(stock, option, riskfree, drift, steps, dt, z)
	}
	else if option.barrier_type == 'UO' && option.opt_type == 'Call' {
		// Price Up and Out Call option
		options = uo_call(stock, option, riskfree, drift, steps, dt, z)
	}
	else if option.barrier_type == 'UO' && option.opt_type == 'Put' {
		// Price Up and Out Put option
		options = uo_put(stock, option, riskfree, drift, steps, dt, z)
	}

	if mean(options) == 0 || mean(options).str() == 'nan' {
		// os.system('clear')
		println('Invalid inputs! Please put a number when asked and corresponding strings!')
		ans := os.input('\n1 - Continue\n0 - Exit\n\n')
		if ans.int() == 1 {
			unsafe {
				goto redo_inputs
			}
		}
		else {
			exit(42)
		}
	}

	z.close()

	option_estimate := math.exp(-riskfree.rate*riskfree.ytd)*mean(options)
	upper_estimate := option_estimate+1.96*std(options)/math.sqrt(options.len)
	lower_estimate := option_estimate-1.96*std(options)/math.sqrt(options.len)
	println('Estimated option price is $option_estimate with confidence interval,
	95% CI:\t [$lower_estimate, $upper_estimate]')

}

fn setup() (Stock,BarrierOption,RiskFreeAsset){
	os.system('clear')
	println('Setting up Monte Carlo Simulation ... \n')

	stock_price := os.input('[Number] Stock price: ').f64()
	stock_vol := os.input('[Number] Stock volatility: ').f64()

	option_strike:= os.input('[Number] Option strike: ').f64()
	option_type := os.input('[String | Call, Put] Option type: ')
	option_barrier_type := os.input('[String | DO, DI, UI, UO] Barrier type: ')
	option_barrier := os.input('[Number] Barrier level: ').f64()
	option_simulations := os.input('[Number] Simulations: ').u64()

	risk_rate := os.input('[Number] Annual Rate: ').f64()
	risk_ytd := os.input('[Number] Years to Maturity: ').f64()

	stock := Stock{
		stock_price, 
		stock_vol
	}

	option := BarrierOption{
		option_strike,
		option_type,
		option_barrier_type,
		option_barrier
		option_simulations
	}

	riskfree := RiskFreeAsset{
		risk_rate,
		risk_ytd
	}
	return stock,option,riskfree
}

fn mean(array []f64) f64{
	// Calculate the mean on an array
	mut sum := 0.0
	for val in array {
		sum += val
	}
	return sum/(array.len)
}

fn std(array []f64) f64{
	// Calculate sample deviation of an array
	mut sum := 0.0
	mu := mean(array)
	for val in array {
		sum += math.pow((val-mu),2)
	}
	return math.sqrt(sum/(array.len - 1))
}

fn monte_carlo_simulation(stock Stock, option BarrierOption, rf RiskFreeAsset,
						 drift f64, steps f64, dt f64, z chan f64) []f64{
	mut stock_prices := [stock.price]
	for i  in 0 .. int(steps) {
		z_i := <- z
		stock_prices << stock_prices[i]*math.exp(drift*dt+
						stock.volatility*math.sqrt(dt)*z_i)
	}
	return stock_prices
}

fn max(array []f64) f64{
	// Function to get maximum of an array.
	mut sorted_array := array.clone()
	sorted_array.sort(a > b)
	return sorted_array[0]
}

fn min(array []f64) f64{
	// Function to get minimum of an array.
	mut sorted_array := array.clone()
	sorted_array.sort(a < b)
	return sorted_array[0]
}

fn do_call(stock Stock, option BarrierOption, rf RiskFreeAsset,
		   drift f64, steps f64, dt f64, z chan f64) []f64{
	strconv.v_printf('\e[?25l')
	mut p := &progressbar.Progressbar{}
	p.new('Process', option.simulations)
	mut do_call := []f64{}
	mut stock_prices := []f64{}
	for sim in 0 .. option.simulations {
		stock_prices = monte_carlo_simulation(stock, option, rf, drift, steps, dt, z)
		if min(stock_prices) < option.barrier{
			do_call << 0.0
		}
		else {
			do_call << math.max((stock_prices.last() - option.strike),0)
		}
		p.increment()
	}
	p.finish()
	strconv.v_printf('\e[?25h')
	return do_call
}

fn do_put(stock Stock, option BarrierOption, rf RiskFreeAsset,
		   drift f64, steps f64, dt f64, z chan f64) []f64{
	strconv.v_printf('\e[?25l')
	mut p := &progressbar.Progressbar{}
	p.new('Process', option.simulations)
	mut do_put := []f64{}
	mut stock_prices := []f64{}
	for sim in 0 .. option.simulations {
		stock_prices = monte_carlo_simulation(stock, option, rf, drift, steps, dt, z)
		if min(stock_prices) < option.barrier{
			do_put << 0.0
		}
		else {
			do_put << math.max((option.strike - stock_prices.last()),0)
		}
		p.increment()
	}
	p.finish()
	strconv.v_printf('\e[?25h')
	return do_put
}

fn di_call(stock Stock, option BarrierOption, rf RiskFreeAsset,
		   drift f64, steps f64, dt f64, z chan f64) []f64{
	strconv.v_printf('\e[?25l')
	mut p := &progressbar.Progressbar{}
	p.new('Process', option.simulations)
	mut di_call := []f64{}
	mut stock_prices := []f64{}
	for sim in 0 .. option.simulations {
		stock_prices = monte_carlo_simulation(stock, option, rf, drift, steps, dt, z)
		if min(stock_prices) < option.barrier{
			di_call << math.max((stock_prices.last() - option.strike),0)
		}
		else {
			di_call << 0.0
		}
		p.increment()
	}
	p.finish()
	strconv.v_printf('\e[?25h')
	return di_call
}

fn di_put(stock Stock, option BarrierOption, rf RiskFreeAsset,
		   drift f64, steps f64, dt f64, z chan f64) []f64{
	strconv.v_printf('\e[?25l')
	mut p := &progressbar.Progressbar{}
	p.new('Process', option.simulations)
	mut di_put := []f64{}
	mut stock_prices := []f64{}
	for sim in 0 .. option.simulations {
		stock_prices = monte_carlo_simulation(stock, option, rf, drift, steps, dt, z)
		if min(stock_prices) < option.barrier{
			di_put << math.max((option.strike - stock_prices.last()),0)
		}
		else {
			di_put << 0.0
		}
		p.increment()
	}
	p.finish()
	strconv.v_printf('\e[?25h')
	return di_put
}

fn uo_call(stock Stock, option BarrierOption, rf RiskFreeAsset,
		   drift f64, steps f64, dt f64, z chan f64) []f64{
	strconv.v_printf('\e[?25l')
	mut p := &progressbar.Progressbar{}
	p.new('Process', option.simulations)
	mut uo_call := []f64{}
	mut stock_prices := []f64{}
	for sim in 0 .. option.simulations {
		stock_prices = monte_carlo_simulation(stock, option, rf, drift, steps, dt, z)
		if max(stock_prices) > option.barrier{
			uo_call << 0.0
		}
		else {
			uo_call << math.max((stock_prices.last() - option.strike),0)
		}
		p.increment()
	}
	p.finish()
	strconv.v_printf('\e[?25h')
	return uo_call
}

fn uo_put(stock Stock, option BarrierOption, rf RiskFreeAsset,
		   drift f64, steps f64, dt f64, z chan f64) []f64{
	strconv.v_printf('\e[?25l')
	mut p := &progressbar.Progressbar{}
	p.new('Process', option.simulations)
	mut uo_put := []f64{}
	mut stock_prices := []f64{}
	for sim in 0 .. option.simulations {
		stock_prices = monte_carlo_simulation(stock, option, rf, drift, steps, dt, z)
		if max(stock_prices) > option.barrier{
			uo_put << 0.0
		}
		else {
			uo_put << math.max((option.strike - stock_prices.last()),0)
		}
		p.increment()
	}
	p.finish()
	strconv.v_printf('\e[?25h')
	return uo_put
}

fn ui_call(stock Stock, option BarrierOption, rf RiskFreeAsset,
		   drift f64, steps f64, dt f64, z chan f64) []f64{
	strconv.v_printf('\e[?25l')
	mut p := &progressbar.Progressbar{}
	p.new('Process', option.simulations)
	mut ui_call := []f64{}
	mut stock_prices := []f64{}
	for sim in 0 .. option.simulations {
		stock_prices = monte_carlo_simulation(stock, option, rf, drift, steps, dt, z)
		if max(stock_prices) > option.barrier{
			ui_call << math.max((stock_prices.last() - option.strike),0)
		}
		else {
			ui_call << 0.0
		}
		p.increment()
	}
	p.finish()
	strconv.v_printf('\e[?25h')
	return ui_call
}

fn ui_put(stock Stock, option BarrierOption, rf RiskFreeAsset,
		   drift f64, steps f64, dt f64, z chan f64) []f64{
	strconv.v_printf('\e[?25l')
	mut p := &progressbar.Progressbar{}
	p.new('Process', option.simulations)
	mut ui_put := []f64{}
	mut stock_prices := []f64{}
	for sim in 0 .. option.simulations {
		stock_prices = monte_carlo_simulation(stock, option, rf, drift, steps, dt, z)
		if max(stock_prices) > option.barrier{
			ui_put << math.max((option.strike - stock_prices.last()),0)
		}
		else {
			ui_put << 0.0
		}
		p.increment()
	}
	p.finish()
	strconv.v_printf('\e[?25h')
	return ui_put
}