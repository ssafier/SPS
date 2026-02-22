<?php

namespace App\Models;

use CodeIgniter\Model;
use App\Entities\StrengthEntry;

class StrengthLog extends Model
{
    protected $DBGroup = 'sps';
    protected $table      = 'strength_log';
    protected $primaryKey = 'id';

    protected $useAutoIncrement = true;

    protected $returnType     = '\App\Entities\StrengthEntry';
    protected $useSoftDeletes = false;

    protected $allowedFields = ['parent', 'xp', 'fatigue', 'bp'];

    // Dates
    protected $useTimestamps = true;
    protected $dateFormat    = 'datetime';
    protected $createdField  = 'inserted_at';
    protected $updatedField  = 'updated_at';
    protected $deletedField  = 'deleted_at';

    // Validation
    protected $validationRules      = [];
    protected $validationMessages   = [];
    protected $skipValidation       = false;
    protected $cleanValidationRules = true;

    // Callbacks
    protected $allowCallbacks = true;
    protected $beforeInsert   = [];
    protected $afterInsert    = [];
    protected $beforeUpdate   = [];
    protected $afterUpdate    = [];
    protected $beforeFind     = [];
    protected $afterFind      = [];
    protected $beforeDelete   = [];
    protected $afterDelete    = [];
}
