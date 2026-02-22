<?php

namespace App\Entities;
use CodeIgniter\Entity\Entity;

class BodyStat extends Entity {
    protected $attributes = [ 
			     'id' => 0,	
			     'player' => 0,
			     'bodypart' => 0,
			     'strength' => 0,
			     'xp' => 0.0,
			     'fatigue' => 0.0,
			     'warmup' => null,
			     'last' => null,
			     'injured' => 0.0,
			     'inserted_at' => null,
			     'updated_at' => null,
			     'deleted_at' => null,
			     ];
   protected $casts = [
        'id' => 'integer',
        'player' => 'integer',
        'bodypart' => 'integer',
        'strength' => 'integer',
        'xp' => 'float',
        'fatigue' => 'float',
        'warmup' => 'datetime',
        'last' => 'datetime',
        'injured' => 'float',
    ];
}

