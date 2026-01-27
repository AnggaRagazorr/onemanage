<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class DokumenMasuk extends Model
{
    use HasFactory;

    protected $table = 'dokumen_masuk';

    protected $fillable = [
        'user_id',
        'date',
        'day',
        'time',
        'origin',
        'item_name',
        'qty',
        'owner',
        'receiver',
    ];
}
