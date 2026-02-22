<?php

namespace App\Entities;
use CodeIgniter\Entity\Entity;

class Lifter extends Entity {
    protected $attributes = [
        'id' => 0,
        'avi' => null,
        'points' => 0,
        'flex' => 0,
        'inserted_at' => null,
        'updated_at' => null,
        'deleted_at' => null,
    ];
    protected $casts = [
        'id' => 'integer',
        'avi' => 'string',
        'points' => 'integer',
        'flex' => 'float',
    ];
}
