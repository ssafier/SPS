<?php

namespace App\Entities;
use CodeIgniter\Entity\Entity;

class Supplement extends Entity {
    protected $attributes = [ 
			     'id' => 0,	
			     'name' => null,
			     'type' => 0,
			     'value' => 0,
			     'injury' => 0,
			     'duration' => null,
			     'cost' => 0,
			     'inserted_at' => null,
			     'updated_at' => null,
			     'deleted_at' => null,
			     ];
   protected $casts = [
        'id' => 'integer',
        'name' => 'string',
        'type' => 'integer',
        'value' => 'integer',
        'injury' => 'integer',
        'duration' => 'string',
        'cost' => 'integer',
    ];
}

