<?php

namespace App\Entities;
use CodeIgniter\Entity\Entity;

class CardioEntry extends Entity {
    protected $attributes = [
        'id' => 0,
        'parent' => 0,
        'xp' => 0,
        'fatigue' => 0,
        'bp' => 0,
        'inserted_at' => null,
        'updated_at' => null,
        'deleted_at' => null,
    ];
    protected $casts = [
        'id' => 'integer',
        'parent' => 'integer',
        'xp' => 'float',
        'fatigue' => 'float',
        'bp' => 'integer',
    ];
}
