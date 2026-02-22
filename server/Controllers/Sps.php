<?php

namespace App\Controllers;

use CodeIgniter\HTTP\RequestInterface;
use CodeIgniter\HTTP\ResponseInterface;
use CodeIgniter\I18n\Time;
use Psr\Log\LoggerInterface;

use App\Models\Lifters;
use App\Models\BodyStats;
use App\Models\Supplements;
use App\Models\Supps;
use App\Models\Cardio;
use App\Models\WorkoutLog;
use App\Models\CardioLog;
use App\Models\StrengthLog;
use App\Models\MassageLog;
use App\Models\StretchingLog;

use App\Entities\Lifter;
use App\Entities\BodyPart;
use App\Entities\Supplement;
use App\Entities\Enhancement;
use App\Entities\CardioWorkout;
use App\Entities\WorkoutEntry;
use App\Entities\StrengthEntry;
use App\Entities\MassageEntry;
use App\Entities\CardioEntry;
use App\Entities\StretchEntry;

class Sps extends BaseController
{
    protected $helpers = ['url'];
    private $players;
    private $body_parts;
    private $supplements;
    private $training_log;
    private $strength_training;
    private $cardio_training;
    private $massages;
    private $cardio;
    private $stretching;
    
    public function initController(
        RequestInterface $request,
        ResponseInterface $response,
        LoggerInterface $logger) {
        parent::initController($request, $response, $logger);
        $this->players = new Lifters();
        $this->body_parts = new BodyStats();
        $this->supplements = new Supps();
        $this->training_log = new WorkoutLog();
        $this->strength_training = new StrengthLog();
        $this->cardio_training = new CardioLog();
        $this->massages = new MassageLog();
        $this->stretching = new StretchingLog();
        $this->cardio = new Cardio();
    }

    private function updateSPS($json, $retval) {
        $p = $this->players->where('avi =',$json['lifter'])->findAll();
        if (!$p || count($p) == 0) {
            $retval[$json['lifter']] = 'error';
            $retval['error'] = 'Unknown player';
        } else {
            return $this->updateSPSstats($json, $retval, $p[0]);
        }
    }

    private function logStrengthWorkout($xp, $fatigue, $bp, $parent) {
        $entry = new \App\Entities\StrengthEntry();
        $entry->xp = $xp;
        $entry->parent = $parent;
        $entry->fatigue = $fatigue;
        $entry->bp = $bp;
        $entry->updated_at = time();
        $entry->inserted_at = time();
        return $this->strength_training->insert($entry);
    }
    
    private function logCardioWorkout($xp, $fatigue, $bp, $parent) {
        $entry = new \App\Entities\CardioEntry();
        $entry->xp = $xp;
        $entry->parent = $parent;
        $entry->fatigue = $fatigue;
        $entry->bp = $bp;
        $entry->updated_at = time();
        $entry->inserted_at = time();
        return $this->cardio_training->insert($entry);
    }

    private function logMassage($fatigue, $parent) {
        $entry = new \App\Entities\MassageEntry();
        $entry->parent = $parent;
        $entry->fatigue = $fatigue;
        $entry->updated_at = time();
        $entry->inserted_at = time();
        return $this->massages->insert($entry);
    }

    private function logStretchingSession($fatigue, $parent, $duration) {
        $entry = new \App\Entities\StretchEntry();
        $entry->parent = $parent;
        $entry->fatigue = $fatigue;
        $entry->duration = $duration;
        $entry->updated_at = time();
        $entry->inserted_at = time();
        return $this->stretching->insert($entry);
    }

    private function logWorkout($type, $duration, $xp, $fatigue, $bp, $id) {
        $threshold = Time::now()->subHours(8);
        $tl = $this->training_log->where('player =', $id)
            ->where('type =', $type)
            ->where('updated_at >', $threshold->toDateTimeString())
            ->findAll();
        if (!$tl || count($tl) == 0) {
            $entry = new \App\Entities\WorkoutEntry();
            $entry->duration = $duration;
            $entry->type = $type;
            $entry->player = $id;
            $entry->updated_at = time();
            $entry->inserted_at = time();
            $parent = $this->training_log->insert($entry);
            $this->logStrengthWorkout($xp, $fatigue, $bp, $parent);
            return $parent;
        } else {
            $entry = $tl[0];
            $entry->duration += $duration;
            $this->logStrengthWorkout($xp, $fatigue, $bp, $entry->id);
            $entry->updated_at = time();
            $this->training_log->update($entry->id, $entry);
            return $entry->id;
        }
    }

    private function updateSPSandLog($json, $retval, $tlog) {
        $p = $this->players->where('avi =',$json['lifter'])->findAll();
        if (!$p || count($p) == 0) {
            $retval[$json['lifter']] = 'error';
            $retval['error'] = 'Unknown player';
        } else {
            $player = $p[0];
            $this->logWorkout(
                $tlog['type'], $tlog['duration'], $tlog['xp'], $tlog['fatigue'], $tlog['bp'], $player->id);
            return $this->updateSPSstats($json, $retval, $player);
        }
    }

    private function updateSPSstats($json, $retval, $player) {
        $retval[$json['lifter']] = 'ok';
        $s = $this->body_parts->where('player =', $player->id)->findAll();
        if ($s != null) {
            $count = count($s);
            // TODO: UTC
            date_default_timezone_set('America/Denver');
            $now = Time::now();
            for ($i = 0; $i < $count; $i++) {
                $updated = false;
                $stat = $s[$i];
                $stat->last = $now;
                switch($stat->bodypart) {
                case 1: // arms
                    if (array_key_exists('arms', $json)) {
                        $updated = true;
                        $arms = $json['arms'];
                        $stat->fatigue = $arms['fatigue'];
                        $stat->strength = $arms['strength'];
                        $stat->xp = $arms['xp'];
                        $stat->injured = $arms['injured'];
                        if ($arms['warmed-up'] == 1) {
                            $stat->warmup = $now;
                        }
                    }
                    break;
                case 2: // core
                    if (array_key_exists('core', $json)) {
                        $updated = true;
                        $core = $json['core'];
                        $stat->fatigue = $core['fatigue'];
                        $stat->strength = $core['strength'];
                        $stat->xp = $core['xp'];
                        $stat->injured = $core['injured'];
                        if ($core['warmed-up'] == 1) {
                            $stat->warmup = $now;
                        }
                    }
                    break;
                case 4: // chest
                    if (array_key_exists('chest', $json)) {
                        $updated = true;
                        $chest = $json['chest'];
                        $stat->fatigue = $chest['fatigue'];
                        $stat->strength = $chest['strength'];
                        $stat->xp = $chest['xp'];
                        $stat->injured = $chest['injured'];
                        if ($chest['warmed-up'] == 1) {
                            $stat->warmup = $now;
                        }
                    }
                    break;
                case 8: // back
                    if (array_key_exists('back', $json)) {
                        $updated = true;
                        $back = $json['back'];
                        $stat->fatigue = $back['fatigue'];
                        $stat->strength = $back['strength'];
                        $stat->xp = $back['xp'];
                        $stat->injured = $back['injured'];
                        if ($back['warmed-up'] == 1) {
                            $stat->warmup = $now;
                        }
                    }
                    break;
                case 16: // legs
                    if (array_key_exists('legs', $json)) {
                        $updated = true;
                        $legs = $json['legs'];
                        $stat->fatigue = $legs['fatigue'];
                        $stat->strength = $legs['strength'];
                        $stat->xp = $legs['xp'];
                        $stat->injured = $legs['injured'];
                        if ($legs['warmed-up'] == 1) {
                            $stat->warmup = $now;
                        }
                    }
                    break;
                default: break;
                }
                if ($updated) $this->body_parts->update($stat->id, $stat);
            }
        }
        if (array_key_exists('dollars', $json)) {
            $player->points = (integer) $json['dollars'] +$player->points;
            $this->players-update($player->id, $player);
        }
        return $retval;
    }

    public function record() {
        $json = $this->request->getJSON(true); // Get JSON as an associative array
        if (!$json) {
            log_message('debug', 'invalid json');
            return;
        }
        $retval = array();
        if (array_key_exists('lifter', $json))
            $retval = $this->updateSPSandLog($json['lifter'], $retval, $json['entry']);
        if (array_key_exists('spotter', $json))
            $retval = $this->updateSPS($json['spotter'], $retval);
        return $this->response->setJSON($retval);        
    }

    public function register() {
        $json = $this->request->getJSON(true); // Get JSON as an associative array
        if (!$json) {
            log_message('debug', 'invalid json');
            return;
        }
        $retval = array();
        $p = $this->players->where('avi =',$json['lifter'])->findAll();
        if (!$p || count($p) == 0) {
            $player = new \App\Entities\Player();
            $player->avi = $json['lifter'];
            $player->updated_at = time();
            $player->inserted_at = time();
            $p = $this->players->insert($player);
            $stats = new \App\Entities\BodyStat();
            $stats->fill($json['arms']);
            $stats->injured = 0;
            $stats->player = $p;
            $stats->updated_at = time();
            $stats->inserted_at = time();
            $stats->bodypart = 1;
            $stats->warmup = time();
            $stats->last = time();                
            $this->body_parts->insert($stats);
            $stats->fill($json['core']);
            $stats->bodypart = 2;
            $this->body_parts->insert($stats);
            $stats->fill($json['chest']);
            $stats->bodypart = 4;
            $this->body_parts->insert($stats);
            $stats->fill($json['back']);
            $stats->bodypart = 8;
            $this->body_parts->insert($stats);
            $stats->fill($json['legs']);
            $stats->bodypart = 16;
            $this->body_parts->insert($stats);
            $tlog = new \App\Entities\WorkoutEntry();
            $tlog->player = $p;
            $tlog->type = 0;
            $tlog->updated_at = time();
            $tlog->inserted_at = time();
            $cardio = new \App\Entities\CardioWorkout();
            $cardio->player = $p;
            $cardio->distance = 900;
            $cardio->duration = 3600;
            $cardio->redline = 1;
            $cardio->type = 0;
            $cardio->log = $this->training_log->insert($tlog);
            $cardio->updated_at = time();
            $cardio->inserted_at = time();
            $this->cardio->insert($cardio);
            $retval['status'] = 'create';
        } else {
            $player = $p[0];
            $s = $this->body_parts->where('player =', $player->id)->findAll();
            $updatedone = false;
            if ($s != null) {
                $count = count($s);
                // TODO: UTC
                date_default_timezone_set('America/Denver');
                $now = Time::now();
                for ($i = 0; $i < $count; $i++) {
                    $updated = false;
                    $stat = $s[$i];
                    $stat->last = $now;
                    switch($stat->bodypart) {
                    case 1: // arms
                        $arms = $json['arms'];
                        if ($arms['strength'] > $stat->strength) {
                            $updated = true;
                            $stat->strength = $arms['strength'];
                            $stat->xp = $arms['xp'];
                        }
                        break;
                    case 2: // core
                        $core = $json['core'];
                        if ($core['strength'] > $stat->strength) {
                            $updated = true;
                            $stat->strength = $core['strength'];
                            $stat->xp = $core['xp'];
                        }
                        break;
                    case 4: // chest
                        $chest = $json['chest'];
                        if ($chest['strength'] > $stat->strength) {
                            $updated = true;
                            $stat->strength = $chest['strength'];
                            $stat->xp = $chest['xp'];
                        }
                        break;
                    case 8: // back
                        $back = $json['back'];
                        if ($back['strength'] > $stat->strength) {
                            $updated = true;
                            $stat->strength = $back['strength'];
                            $stat->xp = $back['xp'];
                        }
                        break;
                    case 16: // legs
                        $legs = $json['legs'];
                        if ($legs['strength'] > $stat->strength) {
                            $updated = true;
                            $stat->strength = $legs['strength'];
                            $stat->xp = $legs['xp'];
                        }
                        break;
                    default: break;
                    }
                    if ($updated) {
                        $this->body_parts->update($stat->id, $stat);
                        $updatedone = true;
                    }
                }
            }
            if ($updatedone) $retval['status'] = 'updated'; else $retval['status'] = 'ok';
        }
        return $this->response->setJSON($retval);        
    }

    private function updateTimeBasedVars($stat, $now, $fatigueRate, $integrityRate) {
        $updated = false;
        $since = $stat->updated_at;
        $interval = $since->diff($now);
        $total = ($interval->days * 24 + $interval->h + ($interval->m / 60.0));
        //        log_message('info','update total is '.strval($total));

        // Fatigue drops (recovers), but rate is slowed by overtraining
        if ($stat->fatigue > 0) {
            $stat->fatigue = max(0, $stat->fatigue - ($total * $fatigueRate / 100.0));
            $updated = true;
        }
        if ($stat->injured > 0) {
            $stat->injured = max(0, $stat->injured - ($total * $integrityRate / 100.0));
            $updated = true;
        }

        if ($updated == true) $this->body_parts->update($stat->id, $stat);
        return $stat;
    }
    
    private function outputBodyStats($s, $output, $fatigueRate, $integrityRate) {
        if ($s != null) {
            $now = Time::now();

            $count = count($s);
            for ($i = 0; $i < $count; $i++) {
                $stat = $this->updateTimeBasedVars($s[$i], $now, $fatigueRate, $integrityRate);
                $interval = $stat->warmup->diff($now);
                $w = 0;
                if ($interval->days == 0 && $interval->h < 4) $w = 1;
                $out = array('strength' => $stat->strength,
                             'xp' => $stat->xp,
                             'fatigue' => $stat->fatigue,
                             'warmed-up' => $w,
                             'injured' => $stat->injured);
                switch($stat->bodypart) {
                case 1: // arms
                    $output['arms'] = json_encode($out);
                    break;
                case 2: // core
                    $output['core'] = json_encode($out);
                    break;
                case 4: // chest
                    $output['chest'] = json_encode($out);
                    break;
                case 8: // back
                    $output['back'] = json_encode($out);
                    break;
                case 16: // legs
                    $output['legs'] = json_encode($out);
                    break;
                default: break;
                }
            }
        }
        return $output;
    }
    
    private function computeRecovery($now, $id, $weeklySessions) {
        $retval = array();
        $recovery = [1,4]; // trenergy and protein

        $onPED = false;
        $protein = false;
        $supplements = $this->supplements
            ->where('player =', $id)
            ->where('expiration >',$now)
            ->whereIn('id',$recovery)
            ->findAll();
        if ($supplements) {
            $count = count($supplements);
            while ($count > 0) {
                --$count;
                $s = $supplements[$count];
                if ($s->id == 1) {
                    $onPED = true;
                } elseif ($s->id == 4) {
                    $protein = true;
                }
            }
        }

        $overtrain = 0;
        $recoveryFactor = 0.4;
        // weekly sessions is from logs (strength)
        if ($onPED) {
            if ($weeklySessions <= 8) $recoveryFactor = 1.0;      // Can train 8x a week fine
            elseif ($weeklySessions <= 12) {
                $recoveryFactor = 0.8; // Minor drop
                $overtrain = 1;
            } else {
                $recoveryFactor = 0.4;
                $overtrain = 2;
            }
        } else {
            // Natural Limits
            if ($weeklySessions <= 4) $recoveryFactor = 1.0;
            elseif ($weeklySessions <= 6) {
                $recoveryFactor = 0.75;
                $overtrain = 1;
            } else {
                $recoveryFactor = 0.4;
                $overtrain = 2;
            }
        }
        
        $integrityFactor = 0.5 * $recoveryFactor;
        if ($protein) {
            $integrityFactor *= 1.5;
        }
        $fatigueRate = 4.0 * $recoveryFactor;
        if ($onPED) {
            $fatigueRate *= 1.5;
        } elseif ($protein) {
            $fatigueRate *= 1.1;
        }
        $retval['fatigue'] = $fatigueRate;
        $retval['integrity'] = $integrityFactor;
        $retval['overtraining'] = $overtrain;
        return $retval;
    }

    private function getWeeklySets($now, $id, $types) {
        $past = Time::now()->subDays(7);
        $result = $this->training_log->where('player =', $id)->where('updated_at >', $past)->whereIn('type',$types)->orderBy('updated_at', 'ASC')->findAll();
        return count($result);
    }

    public function get($avi) {
        $p = $this->players->where('avi =',$avi)->findAll();
        $params = $this->request->getGet();
        if ($p != null && count($p) > 0) {
            $output = array('status' => 'ok');
            $player = $p[0];
            $output['points'] = $player->points;
            $f = $player->flex;
            $player = $this->updateFlexibility($player);
            if ($f != $player->flex) $this->players->update($player->id,$player);
            $output['flexibility'] = $player->flex;
            $messages = array();
            // TODO: UTC
            date_default_timezone_set('America/Denver');
            $output['aerobic'] = $this->cardioFactor($player->id);

            $now = Time::now();
            $strsets = $this->getWeeklySets($now, $player->id, [2]);
            $recovery = $this->computeRecovery($now, $player->id, $strsets);
            $fatigueRate = $recovery['fatigue'];
            $integrityFactor = $recovery['integrity'];
            if ($recovery['overtraining'] != 0) {
                $messages['strength'] ='overtaining';
            }
            
            // cardio
            $strsets = $this->getWeeklySets($now, $player->id, [1]);
            if ($strsets > 5) $messages['cardio'] = 'overtraining';

            $s = $this->body_parts->where('player =', $player->id)->findAll();
            $output = $this->outputBodyStats($s, $output, $fatigueRate, $integrityFactor);
            
            $s = $this->supplements
                ->where('player =', $player->id)
                ->where('expiration >',$now)
                ->findAll();
            if ($s != null) {
                $count = count($s);
                $supplements = array();
                for ($i = 0; $i < $count; $i++) {
                    $supp = $s[$i];
                    $supplements[$supp->name] = strval($supp->supplement);
                }
                $output['supplements'] = json_encode($supplements);
                if (count($messages) > 0) $output['messages'] = json_encode($messages);
            }
        } else {
            $output = array('status' => 'unknown');
        }
        return $this->response->setJSON($output);		
    }

    // TODO: update
    private function muscleRepair($player, $val) {
        $fatigue = $val;
        $injured = $this->body_parts->where('player =', $player->id)->where('injured >',0)->orderBy('injured', 'DESC')->findAll();
        if ($injured != null && count($injured) != 0) {
            $c = count($injured);
            while ($val > 0 && $c > 0) {
                $c = $c - 1;
                $bs = $injured[$c];
                if ($bs->injured < $val) {
                    $val = $val - $bs->injured;
                    $bs->injured = 0;
                } else {
                    $bs->injured = $bs->injured - $val;
                    $val = 0;
                }
                $this->body_parts->update($bs->id, $bs);
            }
        }
        if ($val <= 0) return $fatigue + $val;
        $injured = $this->body_parts->where('player =', $player->id)->where('fatigue >',0)->orderBy('fatigue', 'DESC')->findAll();
        $c = count($injured);
        while ($val > 0 && $c > 0) {
            $c = $c - 1;
            $bs = $injured[$c];
            if ($bs->fatigue < $val) {
                $val = $val - $bs->fatigue;
                $bs->fatigue = 0;
            } else {
                $bs->fatigue = $bs->fatigue - $val;
                $val = 0;
            }
            $this->body_parts->update($bs->id, $bs);
        }
        return $fatigue - $val;
    }

    public function buy($avi, $s) {
        $p = $this->players->where('avi =',$avi)->findAll();
        $output = array();
        if ($p != null && count($p) > 0) {
            $player = $p[0];
                        // TODO: UTC
            date_default_timezone_set('America/Denver');
            $now = Time::now();
            $mys = $this->supplements->where('player =', $player->id)->where('expiration >',$now)->where('supplement = ', $s)->findAll();
            if ($mys == null || count($mys) == 0) {
                $model = new Supplements();
                $supp = $model->where('id =',$s)->findAll();
                $proto = $supp[0];
                if ($proto->cost > $player->points) {
                    $output['status'] = 'insufficient';
                } else {
                    $player->points = $player->points - $proto->cost;
                    if ($s == 3) {
                        //menthol
                        $this->muscleRepair($player, 0.05);
                    } else {
                        $supplement = new \App\Entities\Enhancement();
                        $supplement->player = $player->id;
                        $supplement->supplement = $s;
                        $supplement->name = $proto->name;
                        $supplement->expiration = $now->addSeconds($proto->duration);
                        $this->supplements->insert($supplement);
                    }
                    $player = $this->updateFlexibility($player);
                    $this->players->update($player->id, $player);
                    $output['status'] = 'success';
                }
            } else {
                $output['status'] = 'active';
            }
        } else {
            $output['status'] = 'unknown';
        }
        return $this->response->setJSON($output);		
    }

    public function massage() {
        $json = $this->request->getJSON(true); // Get JSON as an associative array
        if (!$json) {
            log_message('debug', 'invalid json');
            return;
        }
        $retval = array();
        $p = $this->players->where('avi =',$json['masseur'])->findAll();
        if (!$p || count($p) == 0) {
             $retval['status'] = 'error';
            log_message('debug','no masseur '.$json['masseur']);
        } else {
            $mass = $p[0];
            $p = $this->players->where('avi =',$json['client'])->findAll();
            if (!$p || count($p) == 0) {
                $retval['status'] = 'error';
                log_message('debug','no client');
            } else {
                $client = $p[0];
                $dollars = $json['dollars'];
                $fatigue = $this->muscleRepair($client,0.25);
                $mass->points += $dollars;
                $mass = $this->updateFlexibility($mass);
                $this->players->update($mass->id, $mass);
                $tlog = $json['entry'];

                $threshold = Time::now()->subHours(8);
                $tl = $this->training_log->where('player =', $client->id)
                    ->where('type =', 3)
                    ->where('updated_at >', $threshold->toDateTimeString())
                    ->findAll();
                if (!$tl || count($tl) == 0) {
                    $entry = new \App\Entities\WorkoutEntry();
                    $entry->duration = $dollars * 5 * 60;
                    $entry->type = 3;
                    $entry->player = $client->id;
                    $entry->updated_at = time();
                    $entry->inserted_at = time();
                    $parent = $this->training_log->insert($entry);
                    $this->logMassage($fatigue, $parent);
                } else {
                    $entry = $tl[0];
                    $entry->duration += $dollars * 5 * 60;
                    $this->logMassage($fatigue, $entry->id);
                    $entry->updated_at = time();
                    $this->training_log->update($entry->id, $entry);
                }
                $retval['status'] = 'ok';
            } 
        }  
        return $this->response->setJSON($retval);		
    }

    private function cardioFactor($id) {
        $Ago = Time::now()->subMonths(1);
        $result = $this->cardio
            ->select('sum(distance / redline) / sum(duration) as intensity')
            ->where('player =', $id)
            ->where('updated_at >=', $Ago->toDateTimeString())
            ->findAll();
        $intensity = 0.1;
        if ($result && count($result) == 1) {
            $v = $result[0];
            $i = $v->intensity;
            if ($i > $intensity) $intensity = $i;
        }
        return $intensity;
    }

    public function getCardio() {
        $json = $this->request->getJSON(true); // Get JSON as an associative array
        if (!$json) {
            log_message('debug', 'invalid json');
            return;
        }
        $retval = array();
        date_default_timezone_set('America/Denver');
        $p = $this->players->where('avi =',$json['player'])->findAll();
        if (!$p || count($p) == 0) {
            $retval['status'] = 'error';
            log_message('debug','no player');
        } else {
            $player = $p[0];
            date_default_timezone_set('America/Denver');
            $retval['fatigue'] = 0;

            $retval['cardioF'] = $this->cardioFactor($player->id);
            $machine = $json['type'];
            if ($machine == 1 || $machine == 2) {
                $s = $this->body_parts->where('player =', $player->id)->where('bodypart = 16')->findAll();
            } else {
                $s = $this->body_parts->where('player =', $player->id)->where('bodypart = 8')->findAll();
            }

            $now = Time::now();
            $strsets = $this->getWeeklySets($now, $player->id, [1]);
            $recovery = $this->computeRecovery($now, $player->id, $strsets);
            $fatigueRate = $recovery['fatigue'];
            $integrityFactor = $recovery['integrity'];

            $retval = $this->outputBodyStats($s, $retval, $fatigueRate, $integrityFactor);
        } 
        return $this->response->setJSON($retval);		
    }

    public function saveCardio() {
        $json = $this->request->getJSON(true); // Get JSON as an associative array
        if (!$json) {
            log_message('debug', 'invalid json');
            return;
        }
        $retval = array();
        $p = $this->players->where('avi =',$json['lifter'])->findAll();
        if (!$p || count($p) == 0) {
            $retval[$json['lifter']] = 'error';
            $retval['error'] = 'Unknown player';
        } else {
            $player = $p[0];
            $tlog = $json['entry'];
            
            $threshold = Time::now()->subHours(8);
            $tl = $this->training_log->where('player =', $player->id)
                ->where('type =', 1)
                ->where('updated_at >', $threshold->toDateTimeString())
                ->findAll();
            if (!$tl || count($tl) == 0) {
                $entry = new \App\Entities\WorkoutEntry();
                $entry->duration = $tlog['duration'];
                $entry->type = 1;
                $entry->player = $player->id;
                $entry->updated_at = time();
                $entry->inserted_at = time();
                $parent = $this->training_log->insert($entry);
                $this->logCardioWorkout($tlog['xp'], $tlog['fatigue'], $tlog['bp'], $parent);
            } else {
                $entry = $tl[0];
                $entry->duration += $tlog['duration'];
                $this->logCardioWorkout($tlog['xp'], $tlog['fatigue'], $tlog['bp'], $entry->id);
                $entry->updated_at = time();
                $this->training_log->update($entry->id, $entry);
            }

            $c = $json['cardio'];
            $cardio = new \App\Entities\CardioWorkout();
            $cardio->player = $player->id;
            $cardio->distance = $c['distance'];
            $cardio->duration = $c['duration'];
            $cardio->redline = $c['redline'];
            $cardio->type = $c['type'];
            $cardio->log = $entry->id;
            $cardio->updated_at = time();
            $cardio->inserted_at = time();
            $this->cardio->insert($cardio);

            $bodypart = $this->body_parts->where('player =',$player->id)->where('bodypart =',$tlog['bp'])->first();
            $bodypart->fatigue = max(0,min(1, $tlog['fatigue']));
            $xp = $bodypart->xp + $tlog['xp'] / 1000;
            if ($xp > 2) {
                $xp = $xp - (integer) $xp + 1;
            }
            if ($xp > 1) {
                $bodypart->strength++;
                $xp = $xp - 1;
            }
            $bodypart->xp = $xp;
            if ($tlog['duration'] > 300) {
                $bodypart->warmup = time();
            }
            $bodypart->updated_at = time();
            $this->body_parts->update($bodypart->id, $bodypart);
            $retval['status'] = 'create';
        }
        $this->response->setJSON($retval);		
    }

    private function updateForStretching($json, $retval, $player) {
        $retval[$json['yogi']] = 'ok';
        $s = $this->body_parts->where('player =', $player->id)->findAll();
        $count = count($s);
        // TODO: UTC
        date_default_timezone_set('America/Denver');
        $now = Time::now();
        for ($i = 0; $i < $count; $i++) {
            $updated = false;
            $stat = $s[$i];
            $stat->last = $now;
            switch($stat->bodypart) {
            case 1: // arms
                if (array_key_exists('arms', $json)) {
                    $updated = true;
                    $arms = $json['arms'];
                    $stat->fatigue = $arms['fatigue'];
                    $stat->injured = $arms['injured'];
                }
                break;
            case 2: // core
                if (array_key_exists('core', $json)) {
                    $updated = true;
                    $core = $json['core'];
                    $stat->fatigue = $core['fatigue'];
                    $stat->injured = $core['injured'];
                }
                break;
            case 4: // chest
                if (array_key_exists('chest', $json)) {
                    $updated = true;
                    $chest = $json['chest'];
                    $stat->fatigue = $chest['fatigue'];
                    $stat->injured = $chest['injured'];
                }
                break;
            case 8: // back
                if (array_key_exists('back', $json)) {
                    $updated = true;
                    $back = $json['back'];
                    $stat->fatigue = $back['fatigue'];
                    $stat->injured = $back['injured'];
                }
                break;
            case 16: // legs
                if (array_key_exists('legs', $json)) {
                    $updated = true;
                    $legs = $json['legs'];
                    $stat->fatigue = $legs['fatigue'];
                    $stat->injured = $legs['injured'];
                }
                break;
            default: break;
            }
            if ($updated) $this->body_parts->update($stat->id, $stat);
        }
        return $retval;
    }

    private function updateFlexibility($player) {
        $since = $player->updated_at;
        $now = Time::now();
        $interval = $since->diff($now);
        $total = ($interval->days * 24 + $interval->h + ($interval->m / 60.0));
        $player->flex -= 0.05 * ($total / 24);
        if ($player->flex < 0.05) $player->flex = 0.05;
        return $player;
    }

    public function saveStretching() {
        $json = $this->request->getJSON(true); // Get JSON as an associative array
        if (!$json) {
            log_message('debug', 'invalid json');
            return;
        }
        $retval = array();
        $p = $this->players->where('avi =',$json['yogi'])->findAll();
        if (!$p || count($p) == 0) {
            $retval[$json['lifter']] = 'error';
            $retval['error'] = 'Unknown player';
        } else {
            $player = $p[0];
            $tlog = $json['record'];
            
            $threshold = Time::now()->subHours(8);
            $tl = $this->training_log->where('player =', $player->id)
                ->where('type =', 5)
                ->where('updated_at >', $threshold->toDateTimeString())
                ->findAll();
            if (!$tl || count($tl) == 0) {
                $entry = new \App\Entities\WorkoutEntry();
                $entry->duration = $tlog['duration'];
                $entry->type = 1;
                $entry->player = $player->id;
                $entry->updated_at = time();
                $entry->inserted_at = time();
                $parent = $this->training_log->insert($entry);
                $this->logStretchingSession($tlog['fatigue'], $parent, $json['duration']);
            } else {
                $entry = $tl[0];
                $entry->duration += $tlog['duration'];
                $this->logStretchingSession($tlog['fatigue'], $entry->id, $json['duration']);
                $entry->updated_at = time();
                $this->training_log->update($entry->id, $entry);
            }
            $player = $this->updateFlexibility($player);
            $player->flex += $json['flex'];
            if (array_key_exists('dollars', $json)) $player->points += $json['dollars'];
            $this->players->update($player->id, $player);
            $retval = $this->updateForStretching($json, $retval, $player);
        }
        $this->response->setJSON($retval);		
    }
}
