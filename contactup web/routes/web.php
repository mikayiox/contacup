<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider within a group which
| contains the "web" middleware group. Now create something great!
|
*/

Route::get('/', [App\Http\Controllers\contactController::class, "index"]);

Route::post('/contact', [App\Http\Controllers\contactController::class, "store"]);
Route::get('/delcontact/{contact}', [App\Http\Controllers\contactController::class, "destroyMob"]);