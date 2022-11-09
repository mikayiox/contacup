<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken as Middleware;

class VerifyCsrfToken extends Middleware
{
    /**
     * The URIs that should be excluded from CSRF verification.
     *
     * @var array<int, string>
     */
    protected $except = [
        //
        "http://10.0.2.2:8000/contact",
        "http://10.0.2.2:8000/contact/edit/*",
        "http://10.0.2.2:8000/contact/edit/fav/*",

    ];
}