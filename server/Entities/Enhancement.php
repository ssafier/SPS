<?php

namespace App\Entities;
use CodeIgniter\Entity\Entity;

class Enhancement extends Entity {
    protected $attributes = [ 
			     'id' => 0,	
			     'player' => 0,
			     'supplement' => 0,
                 'name' => '',
			     'expiration' => null,
			     'inserted_at' => null,
			     'updated_at' => null,
			     'deleted_at' => null,
			     ];
   protected $casts = [
        'id' => 'integer',
        'player' => 'integer',
        'name' => 'string',
        'supplement' => 'integer',
        'expiration' => 'datetime',
    ];
}

