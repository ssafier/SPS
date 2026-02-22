<?php

namespace App\Entities;
use CodeIgniter\Entity\Entity;

class MassageEntry extends Entity {
    protected $attributes = [
        'id' => 0,
        'parent' => 0,
        'fatigue' => 0,
        'inserted_at' => null,
        'updated_at' => null,
        'deleted_at' => null,
    ];
    protected $casts = [
        'id' => 'integer',
        'parent' => 'integer',
        'fatigue' => 'float',
    ];
}
