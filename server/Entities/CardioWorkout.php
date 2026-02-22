<?php

namespace App\Entities;
use CodeIgniter\Entity\Entity;

class CardioWorkout extends Entity {
    protected $attributes = [
        'id' => 0,
        'player' => 0,
        'type' => 0,
        'distance' => 0,
        'duration' => 0,
        'redline' => 0,
        'log' => 0,
        'inserted_at' => null,
        'updated_at' => null,
        'deleted_at' => null,
    ];
    protected $casts = [
        'id' => 'integer',
        'player' => 'integer',
        'type' => 'integer',
        'distance' => 'float',
        'duration' => 'float',
        'redline' => 'float',
        'log' => 'integer',
    ];
}
