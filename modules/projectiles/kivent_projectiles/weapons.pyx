from kivent_core.systems.staticmemgamesystem cimport (
    StaticMemGameSystem, MemComponent
    )
from kivent_core.memory_handlers.zone cimport MemoryZone
from kivy.factory import Factory
from kivy.properties import (
    StringProperty, BooleanProperty, NumericProperty, ObjectProperty,
    ListProperty
    )
from kivent_cymunk.physics cimport (
    PhysicsStruct
    )
from kivy.factory import Factory
cdef extern from "string.h":
    void *memcpy(void *dest, void *src, size_t n)
from cymunk.cymunk cimport (
    GearJoint, PivotJoint, Vec2d, cpVect, cpv,
    cpFloat, cpBool, cpvunrotate, cpvrotate, cpvdot, cpvsub, cpvnear,
    cpBody, cpvmult, cpvlerp, Space, cpvadd
    )
from kivent_projectiles.projectiles cimport ProjectileSystem
from libc.math cimport cos, sin
include "projectile_config.pxi"


cdef class WeaponTemplate:
    
    def __init__(self, float reload_time, int projectile_type, int ammo_count,
        float rate_of_fire, int clip_size, list barrel_offsets, 
        int barrel_count, int ammo_type, float projectile_width,
        float projectile_height, float accel
        ):
        self.weapon_data.reload_time = reload_time
        self.weapon_data.projectile_type = projectile_type
        self.weapon_data.ammo_count = ammo_count
        self.weapon_data.rate_of_fire = rate_of_fire
        self.weapon_data.clip_size = clip_size
        self.weapon_data.barrel_count = barrel_count
        self.weapon_data.ammo_type = ammo_type
        self.weapon_data.projectile_width = projectile_width
        self.weapon_data.projectile_height = projectile_height
        self.weapon_data.accel = accel
        for i in range(barrel_count):
            self.weapon_data.barrel_offsets[2*i] = barrel_offsets[i][0]
            self.weapon_data.barrel_offsets[2*i+1] = barrel_offsets[i][1]
        self.weapon = Weapon()
        self.weapon.weapon_pointer = &self.weapon_data

    property weapon:
        def __get__(self):
            return self.weapon


cdef class Weapon:

    def __cinit__(self):
        self.weapon_pointer = NULL

    property reload_time:
        def __get__(self):
            return self.weapon_pointer.reload_time
        def __set__(self, float value):
            self.weapon_pointer.reload_time = value

    property projectile_width:
        def __get__(self):
            return self.weapon_pointer.projectile_width
        def __set__(self, float value):
            self.weapon_pointer.projectile_width = value

    property projectile_height:
        def __get__(self):
            return self.weapon_pointer.projectile_height
        def __set__(self, float value):
            self.weapon_pointer.projectile_height = value

    property accel:
        def __get__(self):
            return self.weapon_pointer.accel
        def __set__(self, float value):
            self.weapon_pointer.accel = value

    property projectile_type:
        def __get__(self):
            return self.weapon_pointer.projectile_type
        def __set__(self, int value):
            self.weapon_pointer.projectile_type = value

    property in_clip:
        def __get__(self):
            return self.weapon_pointer.in_clip
        def __set__(self, int value):
            self.weapon_pointer.in_clip = value

    property ammo_count:
        def __get__(self):
            return self.weapon_pointer.ammo_count
        def __set__(self, int value):
            self.weapon_pointer.ammo_count = value

    property clip_size:
        def __get__(self):
            return self.weapon_pointer.clip_size
        def __set__(self, int value):
            self.weapon_pointer.clip_size = value

    property rate_of_fire:
        def __get__(self):
            return self.weapon_pointer.rate_of_fire
        def __set__(self, float value):
            self.weapon_pointer.rate_of_fire = value

    property ammo_type:
        def __get__(self):
            return self.weapon_pointer.ammo_type
        def __set__(self, int value):
            self.weapon_pointer.ammo_type = value

    property barrel_count:
        def __get__(self):
            return self.weapon_pointer.barrel_count
        def __set__(self, int value):
            self.weapon_pointer.barrel_count = value

    property barrel_offsets:
        def __get__(self):
            cdef float* barrel_offsets = self.weapon_pointer.barrel_offsets
            return [
                (barrel_offsets[2*x], barrel_offsets[2*x+1]) for x in range(
                    self.weapon_pointer.barrel_count)
                ]
        def __set__(self, list new_offsets):
            cdef tuple offsets
            cdef float* barrel_offsets = self.weapon_pointer.barrel_offsets
            for x in range(self.weapon_pointer.barrel_count):
                offsets = new_offsets[x]
                barrel_offsets[2*x] = offsets[0]
                barrel_offsets[2*x+1] = offsets[1]


cdef class ProjectileWeaponComponent(MemComponent):

    property entity_id:
        def __get__(self):
            cdef ProjectileWeaponStruct* data = <ProjectileWeaponStruct*>(
                self.pointer
                )
            return data.entity_id

    property current_weapon:
        def __get__(self):
            cdef ProjectileWeaponStruct* data = <ProjectileWeaponStruct*>(
                self.pointer
                )
            return data.current_weapon
        def __set__(self, int value):
            cdef ProjectileWeaponStruct* data = <ProjectileWeaponStruct*>(
                self.pointer
                )
            data.current_weapon = value

    property weapons:
        def __get__(self):
            cdef ProjectileWeaponStruct* data = <ProjectileWeaponStruct*>(
                self.pointer
                )
            cdef list return_list = []
            cdef ProjectileWeapon* weapon_pointer
            cdef Weapon weapon
            for x in range(MAX_WEAPONS):
                weapon_pointer = &data.weapons[x]
                weapon = Weapon()
                weapon.weapon_pointer = weapon_pointer
                return_list.append(weapon)
            return return_list

    property firing:
        def __get__(self):
            cdef ProjectileWeaponStruct* data = <ProjectileWeaponStruct*>(
                self.pointer
                )
            return data.firing
        def __set__(self, bint value):
            cdef ProjectileWeaponStruct* data = <ProjectileWeaponStruct*>(
                self.pointer
                )
            data.firing = value

    property reloading:
        def __get__(self):
            cdef ProjectileWeaponStruct* data = <ProjectileWeaponStruct*>(
                self.pointer
                )
            return data.reloading
        def __set__(self, bint value):
            cdef ProjectileWeaponStruct* data = <ProjectileWeaponStruct*>(
                self.pointer
                )
            data.reloading = value

    property cooldown:
        def __get__(self):
            cdef ProjectileWeaponStruct* data = <ProjectileWeaponStruct*>(
                self.pointer
                )
            return data.cooldown
        def __set__(self, float value):
            cdef ProjectileWeaponStruct* data = <ProjectileWeaponStruct*>(
                self.pointer
                )
            data.cooldown = value


class TooManyWeapons(Exception):
    pass


cdef cpVect get_rotated_vector(float angle, float x, float y):
        return cpv((y * cos(angle)) - (x * sin(angle)), 
            (x * cos(angle)) + (y * sin(angle)))


cdef class ProjectileWeaponSystem(StaticMemGameSystem):
    system_id = StringProperty('projectile_weapons')
    updateable = BooleanProperty(True)
    processor = BooleanProperty(True)
    type_size = NumericProperty(sizeof(ProjectileWeaponStruct))
    component_type = ObjectProperty(ProjectileWeaponComponent)
    system_names = ListProperty(['projectile_weapons','cymunk_physics'])
    projectile_system = ObjectProperty(None)

    def __init__(self, **kwargs):
        super(ProjectileWeaponSystem, self).__init__(**kwargs)
        self.weapon_templates = {}


    cdef void copy_template_to_weapon(self, str template_name, 
        ProjectileWeapon *weapon):
        cdef WeaponTemplate template = self.weapon_templates[template_name]
        memcpy(<char *>weapon, &template.weapon_data, sizeof(ProjectileWeapon))


    def register_weapon_template(self, str template_name, float reload_time, 
        int projectile_type, int ammo_count,
        float rate_of_fire, int clip_size, list barrel_offsets, 
        int barrel_count, int ammo_type, float projectile_width,
        float projectile_height, float accel):
        self.weapon_templates[template_name] = WeaponTemplate(
            reload_time, projectile_type, ammo_count, rate_of_fire, clip_size,
            barrel_offsets, barrel_count, ammo_type, projectile_width,
            projectile_height, accel
            )


    def set_weapon_at_position(self, unsigned int entity_id, str weapon_name,
        int index):
        entity = self.gameworld.entities[entity_id]
        cdef ProjectileWeaponComponent weapon_comp = entity.projectile_weapons
        cdef ProjectileWeaponStruct* data = <ProjectileWeaponStruct*>(
            weapon_comp.pointer
            )
        self.copy_template_to_weapon(weapon_name, &data.weapons[index])


    def init_component(self, unsigned int component_index, 
        unsigned int entity_id, str zone_name, dict args):
        '''
        '''
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef ProjectileWeaponStruct* component = <ProjectileWeaponStruct*>(
            memory_zone.get_pointer(component_index)
            )
        component.entity_id = entity_id
        component.current_weapon = 0
        component.cooldown = 0.0
        component.firing = 0
        component.reloading = 0
        cdef ProjectileWeapon *weapon
        for x in range(MAX_WEAPONS):
            weapon = &component.weapons[x]
            weapon.projectile_type = NO_WEAPON
        weapons_to_initialize = args.get('weapons', [])
        if len(weapons_to_initialize) > MAX_WEAPONS:
            raise TooManyWeapons(
                '''Tried to add too many weapons, MAX_WEAPONS is {max}, you 
                can raise this value by setting MAX_WEAPONS in 
                projectile_config.pxi and recompiling the projectiles module.
                '''.format(max=MAX_WEAPONS)
                )
        for index, each in enumerate(weapons_to_initialize):
            self.copy_template_to_weapon(each, &component.weapons[index])
        return self.entity_components.add_entity(entity_id, zone_name)


    def clear_component(self, unsigned int component_index):
        '''
        '''
        cdef MemoryZone memory_zone = self.imz_components.memory_zone
        cdef ProjectileWeaponStruct* component = <ProjectileWeaponStruct*>(
            memory_zone.get_pointer(component_index))
        component.entity_id = -1
        component.current_weapon = 0
        for x in range(MAX_WEAPONS):
            weapon = &component.weapons[x]
            weapon.projectile_type = NO_WEAPON


    def remove_component(self, unsigned int component_index):
        cdef ProjectileWeaponComponent component = (
            self.components[component_index])
        self.entity_components.remove_entity(component.entity_id)
        super(ProjectileWeaponSystem, self).remove_component(component_index)

    cdef void fire_projectile(self, unsigned int entity_id, float accel):
        entities = self.gameworld.entities
        bullet = entities[entity_id]
        physics_data = bullet.cymunk_physics
        unit_vector = physics_data.unit_vector
        force = accel*unit_vector[0], accel*unit_vector[1]
        force_offset = -unit_vector[0], -unit_vector[1]
        bullet_body = physics_data.body
        bullet_body.apply_impulse(force, force_offset)


    def update(self, float dt):
        #cooldown = min(0.0, cooldown - dt)
        #check if need reload (in_clip == 0):
        #cooldown += reload_time
        #reloading = True
        # if reloading = True and cooldown <= .00 reloading = False
        #in_clip += clip_size
        #check if firing and cooldown <= .00, fire projectile
        cdef ProjectileWeaponStruct* system_comp
        cdef PhysicsStruct* physics_comp
        cdef ProjectileWeapon* weapon
        cdef ProjectileSystem projectile_system = self.projectile_system
        cdef void** component_data = <void**>(
            self.entity_components.memory_block.data)
        cdef unsigned int component_count = self.entity_components.count
        cdef unsigned int count = self.entity_components.memory_block.count
        cdef unsigned int i, real_index, x, bullet_ent
        cdef float threshold = .00001
        cdef cpBody* body
        cdef cpVect rotated_vec, bullet_position

        for i in range(count):
            real_index = i*component_count
            if component_data[real_index] == NULL:
                continue

            system_comp = <ProjectileWeaponStruct*>component_data[real_index]
            physics_comp = <PhysicsStruct*>component_data[real_index+1]
            weapon = &system_comp.weapons[system_comp.current_weapon]
            system_comp.cooldown = max(0.0, system_comp.cooldown - dt)
            if weapon.in_clip == 0 and not system_comp.reloading:
                system_comp.cooldown += weapon.reload_time
                system_comp.reloading = 1
            if system_comp.reloading and system_comp.cooldown <= threshold:
                system_comp.reloading = 0
                weapon.in_clip = weapon.clip_size

            if system_comp.firing and system_comp.cooldown <= threshold:
                system_comp.cooldown += weapon.rate_of_fire
                system_comp.firing = 0
                weapon.in_clip -= weapon.barrel_count
                for x in range(weapon.barrel_count):
                    x_offset = weapon.barrel_offsets[2*x] + (
                        weapon.projectile_width*.5)
                    y_offset = weapon.barrel_offsets[2*x+1]
                    body = physics_comp.body
                    rotated_vec = get_rotated_vector(
                        body.a, x_offset, y_offset
                        )
                    bullet_position = cpvadd(rotated_vec, body.p)
                    bullet_ent = projectile_system.create_projectile(
                        weapon.ammo_type, 
                        (bullet_position.x, bullet_position.y),
                        body.a, system_comp.entity_id
                        )
                    self.fire_projectile(bullet_ent, weapon.accel)



    property weapon_templates:
        def __get__(self):
            return self.weapon_templates
        
Factory.register('ProjectileWeaponSystem', cls=ProjectileWeaponSystem)